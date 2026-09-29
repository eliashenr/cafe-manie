class_name Kitchen
extends RefCounted
## Fogões e balcões: o que está cozinhando e quantas porções estão prontas.
##
## O preparo é guardado como "receita + horário de início". O estado
## (cozinhando / pronto) é calculado a partir do relógio, então um prato
## continua ficando pronto com o jogo fechado.
##
## A Kitchen não cobra nem paga nada: quem orquestra dinheiro e XP é a
## CafeSimulation.

## Emitido quando começa um preparo, um prato vai para o balcão ou uma porção sai.
signal changed

enum StoveStatus { IDLE, COOKING, READY }


class StoveState:
	extends RefCounted
	var recipe: RecipeDefinition
	var started_at: float


class CounterStack:
	extends RefCounted
	var recipe: RecipeDefinition
	var servings: int


var clock: GameClock
var layout: CafeLayout
## Porções que cabem em um balcão.
var counter_capacity: int

var _stoves: Dictionary = {}  # id do fogão -> StoveState
var _counters: Dictionary = {}  # id do balcão -> CounterStack


func _init(game_clock: GameClock, cafe_layout: CafeLayout, capacity: int) -> void:
	clock = game_clock
	layout = cafe_layout
	counter_capacity = capacity
	layout.changed.connect(_forget_removed)


func is_stove(id: StringName) -> bool:
	return _category_of(id) == FurnitureDefinition.Category.COOKING


func is_counter(id: StringName) -> bool:
	return _category_of(id) == FurnitureDefinition.Category.COUNTER


# --- Fogões ----------------------------------------------------------------

func stove_status(id: StringName) -> StoveStatus:
	var state: StoveState = _stoves.get(id)
	if state == null:
		return StoveStatus.IDLE
	return StoveStatus.READY if clock.now() >= state.started_at + state.recipe.cook_time else StoveStatus.COOKING


## Receita no fogão (cozinhando ou pronta), ou null se estiver livre.
func stove_recipe(id: StringName) -> RecipeDefinition:
	var state: StoveState = _stoves.get(id)
	return state.recipe if state != null else null


## Segundos que faltam para ficar pronto (0 se pronto ou livre).
func time_left(id: StringName) -> float:
	var state: StoveState = _stoves.get(id)
	if state == null:
		return 0.0
	return maxf(state.started_at + state.recipe.cook_time - clock.now(), 0.0)


## Fração do preparo concluída (0 a 1). Livre = 0.
func progress(id: StringName) -> float:
	var state: StoveState = _stoves.get(id)
	if state == null:
		return 0.0
	return clampf((clock.now() - state.started_at) / state.recipe.cook_time, 0.0, 1.0)


func start_cooking(stove_id: StringName, recipe: RecipeDefinition) -> int:
	if not is_stove(stove_id):
		return ServiceResult.NOT_A_STOVE
	if _stoves.has(stove_id):
		return ServiceResult.STOVE_BUSY
	var state := StoveState.new()
	state.recipe = recipe
	state.started_at = clock.now()
	_stoves[stove_id] = state
	changed.emit()
	return ServiceResult.OK


## Leva o prato pronto para um balcão: primeiro um que já tenha a mesma
## receita e espaço; senão, um balcão vazio.
func collect(stove_id: StringName) -> int:
	if not is_stove(stove_id):
		return ServiceResult.NOT_A_STOVE
	if stove_status(stove_id) != StoveStatus.READY:
		return ServiceResult.NOT_READY
	var recipe: RecipeDefinition = _stoves[stove_id].recipe
	var counter_id := _find_counter_for(recipe, recipe.servings)
	if counter_id == &"":
		return ServiceResult.NO_COUNTER_SPACE
	_add_to_counter(counter_id, recipe, recipe.servings)
	_stoves.erase(stove_id)
	changed.emit()
	return ServiceResult.OK


# --- Balcões ---------------------------------------------------------------

## O que está no balcão, ou null se vazio.
func counter_stack(id: StringName) -> CounterStack:
	return _counters.get(id)


## Receitas com pelo menos uma porção em algum balcão (sem repetição).
func available_recipes() -> Array[RecipeDefinition]:
	var result: Array[RecipeDefinition] = []
	for counter_id in _counter_ids():
		var stack: CounterStack = _counters.get(counter_id)
		if stack != null and not result.has(stack.recipe):
			result.append(stack.recipe)
	return result


func servings_of(recipe: RecipeDefinition) -> int:
	var total := 0
	for stack: CounterStack in _counters.values():
		if stack.recipe == recipe:
			total += stack.servings
	return total


## Tira uma porção da receita de algum balcão. Retorna o id do balcão, ou &"" se não houver.
func take_serving(recipe: RecipeDefinition) -> StringName:
	for counter_id in _counter_ids():
		var stack: CounterStack = _counters.get(counter_id)
		if stack != null and stack.recipe == recipe:
			stack.servings -= 1
			if stack.servings <= 0:
				_counters.erase(counter_id)
			changed.emit()
			return counter_id
	return &""


## Devolve uma porção não servida. Prefere o balcão de origem. Retorna false se não couber em nenhum.
func return_serving(counter_id: StringName, recipe: RecipeDefinition) -> bool:
	var target := counter_id if _fits(counter_id, recipe, 1) else _find_counter_for(recipe, 1)
	if target == &"":
		return false
	_add_to_counter(target, recipe, 1)
	changed.emit()
	return true


## Um fogão com preparo ou um balcão com comida não pode ser movido nem removido.
func is_in_use(id: StringName) -> bool:
	return _stoves.has(id) or _counters.has(id)


# --- Interno ---------------------------------------------------------------

func _category_of(id: StringName) -> int:
	var placement := layout.get_placement(id)
	return placement.definition.category if placement != null else -1


## Balcões em ordem estável (id), para o comportamento ser previsível.
func _counter_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for placement in layout.placements():
		if placement.definition.category == FurnitureDefinition.Category.COUNTER:
			ids.append(placement.id)
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


func _fits(counter_id: StringName, recipe: RecipeDefinition, amount: int) -> bool:
	if not is_counter(counter_id):
		return false
	var stack: CounterStack = _counters.get(counter_id)
	if stack == null:
		return amount <= counter_capacity
	return stack.recipe == recipe and stack.servings + amount <= counter_capacity


func _find_counter_for(recipe: RecipeDefinition, amount: int) -> StringName:
	var ids := _counter_ids()
	for counter_id in ids:
		if _counters.has(counter_id) and _fits(counter_id, recipe, amount):
			return counter_id
	for counter_id in ids:
		if not _counters.has(counter_id) and _fits(counter_id, recipe, amount):
			return counter_id
	return &""


func _add_to_counter(counter_id: StringName, recipe: RecipeDefinition, amount: int) -> void:
	var stack: CounterStack = _counters.get(counter_id)
	if stack == null:
		stack = CounterStack.new()
		stack.recipe = recipe
		stack.servings = 0
		_counters[counter_id] = stack
	stack.servings += amount


## Defesa: se um fogão ou balcão sumir do layout, o estado dele some junto.
func _forget_removed() -> void:
	for id: StringName in _stoves.keys():
		if layout.get_placement(id) == null:
			_stoves.erase(id)
	for id: StringName in _counters.keys():
		if layout.get_placement(id) == null:
			_counters.erase(id)
