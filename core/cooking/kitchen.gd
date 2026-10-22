class_name Kitchen
extends RefCounted
## Fogões e balcões: o que está cozinhando e quantas porções estão prontas.
##
## O preparo é guardado como "receita + horário de início". O estado
## (cozinhando / pronto / estragado) é calculado a partir do relógio, então um
## prato continua ficando pronto (e estragando, se for esquecido) com o jogo
## fechado. Com o jogo pausado, o tempo dos fogões para; ao continuar, cada
## preparo segue de onde parou.
##
## A Kitchen não cobra nem paga nada: quem orquestra dinheiro e XP é a
## CafeSimulation.

## Emitido quando começa um preparo, um prato vai para o balcão ou uma porção sai.
signal changed

enum StoveStatus { IDLE, COOKING, READY, SPOILED }


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
## Quanto o prato pronto aguenta no fogão antes de estragar (DT-055): o tempo de preparo vezes
## spoil_factor, e nunca menos que min_spoil_time. Com spoil_factor 0, nada estraga.
var spoil_factor := 0.0
var min_spoil_time := 0.0

var _stoves: Dictionary = {}  # id do fogão -> StoveState
var _counters: Dictionary = {}  # id do balcão -> CounterStack
## Horário do relógio em que o jogo foi pausado (-1 = rodando).
var _paused_at := -1.0


func _init(game_clock: GameClock, cafe_layout: CafeLayout, capacity: int) -> void:
	clock = game_clock
	layout = cafe_layout
	counter_capacity = capacity
	layout.changed.connect(_forget_removed)


func is_stove(id: StringName) -> bool:
	return _category_of(id) == FurnitureDefinition.Category.COOKING


func is_counter(id: StringName) -> bool:
	return _category_of(id) == FurnitureDefinition.Category.COUNTER


# --- Pausa ----------------------------------------------------------------

## Para (ou volta a correr) o tempo dos fogões. Ao voltar, todo preparo anda o tempo da pausa para a frente.
func set_paused(value: bool) -> void:
	if value == is_paused():
		return
	if value:
		_paused_at = clock.now()
		return
	var pause := clock.now() - _paused_at
	_paused_at = -1.0
	for state: StoveState in _stoves.values():
		state.started_at += pause


func is_paused() -> bool:
	return _paused_at >= 0.0


## Agora, para os fogões: o relógio, ou o horário em que o jogo foi pausado.
func now() -> float:
	return _paused_at if is_paused() else clock.now()


## Quanto o tempo da pausa atual já empurrou os preparos (0 rodando).
func _pause_shift() -> float:
	return clock.now() - _paused_at if is_paused() else 0.0


# --- Fogões ----------------------------------------------------------------

func stove_status(id: StringName) -> StoveStatus:
	var state: StoveState = _stoves.get(id)
	return _status_of(state) if state != null else StoveStatus.IDLE


## Segundos que um prato pronto desta receita aguenta no fogão (INF se nada estraga).
func spoil_time(recipe: RecipeDefinition) -> float:
	if spoil_factor <= 0.0:
		return INF
	return maxf(recipe.cook_time * spoil_factor, min_spoil_time)


## Segundos que faltam para o prato pronto estragar (0 se não está pronto).
func time_to_spoil(id: StringName) -> float:
	var state: StoveState = _stoves.get(id)
	if state == null or _status_of(state) != StoveStatus.READY:
		return 0.0
	return state.started_at + state.recipe.cook_time + spoil_time(state.recipe) - now()


## Receita no fogão (cozinhando ou pronta), ou null se estiver livre.
func stove_recipe(id: StringName) -> RecipeDefinition:
	var state: StoveState = _stoves.get(id)
	return state.recipe if state != null else null


## Segundos que faltam para ficar pronto (0 se pronto ou livre).
func time_left(id: StringName) -> float:
	var state: StoveState = _stoves.get(id)
	if state == null:
		return 0.0
	return maxf(state.started_at + state.recipe.cook_time - now(), 0.0)


## Fração do preparo concluída (0 a 1). Livre = 0.
func progress(id: StringName) -> float:
	var state: StoveState = _stoves.get(id)
	if state == null:
		return 0.0
	return clampf((now() - state.started_at) / state.recipe.cook_time, 0.0, 1.0)


func start_cooking(stove_id: StringName, recipe: RecipeDefinition) -> int:
	if not is_stove(stove_id):
		return ServiceResult.NOT_A_STOVE
	if _stoves.has(stove_id):
		return ServiceResult.STOVE_BUSY
	var state := StoveState.new()
	state.recipe = recipe
	state.started_at = now()
	_stoves[stove_id] = state
	changed.emit()
	return ServiceResult.OK


## Leva o prato pronto para um balcão: primeiro um que já tenha a mesma
## receita e espaço; senão, um balcão vazio.
func collect(stove_id: StringName) -> int:
	if not is_stove(stove_id):
		return ServiceResult.NOT_A_STOVE
	match stove_status(stove_id):
		StoveStatus.SPOILED:
			return ServiceResult.SPOILED
		StoveStatus.IDLE, StoveStatus.COOKING:
			return ServiceResult.NOT_READY
	var recipe: RecipeDefinition = _stoves[stove_id].recipe
	var counter_id := _find_counter_for(recipe, recipe.servings)
	if counter_id == &"":
		return ServiceResult.NO_COUNTER_SPACE
	_add_to_counter(counter_id, recipe, recipe.servings)
	_stoves.erase(stove_id)
	changed.emit()
	return ServiceResult.OK


## Joga fora o prato estragado e deixa o fogão livre.
func discard(stove_id: StringName) -> int:
	if not is_stove(stove_id):
		return ServiceResult.NOT_A_STOVE
	if stove_status(stove_id) != StoveStatus.SPOILED:
		return ServiceResult.NOT_SPOILED
	_stoves.erase(stove_id)
	changed.emit()
	return ServiceResult.OK


# --- Balcões ---------------------------------------------------------------

## Algum fogão está preparando esta receita (ou já terminou e o prato espera ser levado)? Estragado não conta.
func is_preparing(recipe: RecipeDefinition) -> bool:
	for state: StoveState in _stoves.values():
		if state.recipe == recipe and _status_of(state) != StoveStatus.SPOILED:
			return true
	return false


## Fogões com prato pronto, em ordem estável (id).
func ready_stoves() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in _stoves.keys():
		if stove_status(id) == StoveStatus.READY:
			ids.append(id)
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


## Fogões com prato estragado, em ordem estável (id).
func spoiled_stoves() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in _stoves.keys():
		if stove_status(id) == StoveStatus.SPOILED:
			ids.append(id)
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


## Balcão para onde iria o prato pronto deste fogão; &"" se não está pronto ou não cabe em nenhum.
func collect_destination(stove_id: StringName) -> StringName:
	if stove_status(stove_id) != StoveStatus.READY:
		return &""
	var recipe: RecipeDefinition = _stoves[stove_id].recipe
	return _find_counter_for(recipe, recipe.servings)


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


## Horário (do relógio do jogo) em que o prato do fogão fica pronto; -1 se livre. Pausado, conta a pausa até agora.
func stove_ready_at(id: StringName) -> float:
	var state: StoveState = _stoves.get(id)
	return state.started_at + state.recipe.cook_time + _pause_shift() if state != null else -1.0


# --- Save ------------------------------------------------------------------

## Estado dos fogões e balcões em tipos simples (para JSON).
func to_data() -> Dictionary:
	var stoves: Array[Dictionary] = []
	for id: StringName in _stoves:
		var state: StoveState = _stoves[id]
		# salvo durante a pausa: o tempo dela não conta como cozinhado
		stoves.append({"id": String(id), "recipe": String(state.recipe.id), "started_at": state.started_at + _pause_shift()})
	var counters: Array[Dictionary] = []
	for id: StringName in _counters:
		var stack: CounterStack = _counters[id]
		counters.append({"id": String(id), "recipe": String(stack.recipe.id), "servings": stack.servings})
	return {"stoves": stoves, "counters": counters}


## Restaura um preparo salvo, com o horário original de início.
func restore_stove(id: StringName, recipe: RecipeDefinition, started_at: float) -> bool:
	if recipe == null or not is_stove(id) or _stoves.has(id):
		return false
	var state := StoveState.new()
	state.recipe = recipe
	state.started_at = started_at
	_stoves[id] = state
	changed.emit()
	return true


## Restaura porções num balcão (soma se já houver a mesma receita). Respeita a capacidade.
func restore_counter(id: StringName, recipe: RecipeDefinition, servings: int) -> bool:
	if recipe == null or servings <= 0 or not _fits(id, recipe, servings):
		return false
	_add_to_counter(id, recipe, servings)
	changed.emit()
	return true


## Um fogão com preparo ou um balcão com comida não pode ser movido nem removido.
func is_in_use(id: StringName) -> bool:
	return _stoves.has(id) or _counters.has(id)


# --- Interno ---------------------------------------------------------------

func _status_of(state: StoveState) -> StoveStatus:
	var ready_at := state.started_at + state.recipe.cook_time
	if now() < ready_at:
		return StoveStatus.COOKING
	return StoveStatus.SPOILED if now() >= ready_at + spoil_time(state.recipe) else StoveStatus.READY


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
