class_name MissionBoard
extends RefCounted
## Quadro de missões de um período (as diárias ou as semanais): todas valem ao mesmo tempo e recomeçam
## do zero quando o período muda (outro dia, outra semana). As metas e as recompensas acompanham o nível
## e ficam congeladas no começo do período. Missão com nível mínimo maior que o do jogador fica com o
## cadeado e não conta até o próximo período.
##
## Recebe eventos do jogo (record) e avisa quando uma missão é concluída. Quem entrega a recompensa é a
## CafeSimulation.

signal mission_completed(entry: Entry)
signal changed

## Uma missão no período atual: a meta e a recompensa congeladas, o progresso e se já foi concluída.
class Entry:
	extends RefCounted

	var mission: MissionDefinition
	var target := 1
	var progress := 0
	var reward_gold := 0
	var reward_xp := 0
	var locked := false

	func done() -> bool:
		return not locked and progress >= target

	func title() -> String:
		return mission.title_for(target)


var missions: Array[MissionDefinition] = []
## Período das metas atuais (dia ou semana, conforme quem usa); -1 = ainda não começou.
var period := -1

var _entries: Array[Entry] = []
## Receitas já cozinhadas no período (para "pratos diferentes").
var _recipes_cooked: Dictionary = {}


func _init(mission_list: Array[MissionDefinition]) -> void:
	missions = mission_list.duplicate()
	missions.sort_custom(func(a: MissionDefinition, b: MissionDefinition) -> bool: return a.order < b.order)


func entries() -> Array[Entry]:
	return _entries


func completed_count() -> int:
	return _entries.filter(func(entry: Entry) -> bool: return entry.done()).size()


func size() -> int:
	return _entries.size()


## Começa o período [param new_period] se ainda não é o atual: tudo do zero, com metas e recompensas do
## nível [param level] ([param unlocked_recipes] limita "pratos diferentes"). Retorna se recomeçou.
func start_period(new_period: int, level: int, unlocked_recipes: int) -> bool:
	if new_period == period:
		return false
	period = new_period
	_recipes_cooked.clear()
	_entries.clear()
	for mission in missions:
		var entry := Entry.new()
		entry.mission = mission
		entry.locked = mission.min_level > level
		entry.target = mission.target_at(level, unlocked_recipes)
		entry.reward_gold = mission.reward_gold_at(level)
		entry.reward_xp = mission.reward_xp_at(level)
		_entries.append(entry)
	changed.emit()
	return true


## Registra um evento. [param recipe] serve para "pratos diferentes" e "pratos demorados";
## [param furniture_category] para compras de uma categoria. Para estados (popularidade),
## [param amount] é o valor atual.
func record(kind: MissionDefinition.Kind, amount := 1, recipe: RecipeDefinition = null, furniture_category := -1) -> void:
	if _entries.is_empty():
		return
	if kind == MissionDefinition.Kind.COOK_DIFFERENT:
		if recipe == null or _recipes_cooked.has(recipe.id):
			return
		_recipes_cooked[recipe.id] = true
	var touched := false
	var finished: Array[Entry] = []
	for entry in _entries:
		var mission := entry.mission
		if entry.locked or entry.done() or mission.kind != kind:
			continue
		if kind == MissionDefinition.Kind.BUY_FURNITURE and mission.furniture_category >= 0 \
				and mission.furniture_category != furniture_category:
			continue
		if kind == MissionDefinition.Kind.COOK_SLOW and (recipe == null or recipe.cook_time < mission.min_cook_time):
			continue
		var before := entry.progress
		entry.progress = maxi(entry.progress, amount) if mission.is_state() else entry.progress + amount
		entry.progress = mini(entry.progress, entry.target)
		touched = touched or entry.progress != before
		if entry.done():
			finished.append(entry)
	if touched:
		changed.emit()
	for entry in finished:
		mission_completed.emit(entry)


func to_data() -> Dictionary:
	var progress := {}
	for entry in _entries:
		progress[String(entry.mission.id)] = [entry.progress, entry.target, entry.reward_gold, entry.reward_xp, entry.locked]
	return {"period": period, "entries": progress, "recipes": _recipes_cooked.keys().map(func(id: StringName) -> String: return String(id))}


## Restaura o período salvo. Missão nova (que não estava no save) entra com a meta do nível
## [param level]; missão que saiu do jogo é ignorada.
func restore(data: Dictionary, level: int, unlocked_recipes: int) -> void:
	period = -1
	start_period(int(data.get("period", -1)), level, unlocked_recipes)
	var saved: Dictionary = data.get("entries", {})
	for entry in _entries:
		var values: Array = saved.get(String(entry.mission.id), [])
		if values.size() == 5:
			entry.target = maxi(int(values[1]), 1)
			entry.progress = clampi(int(values[0]), 0, entry.target)
			entry.reward_gold = maxi(int(values[2]), 0)
			entry.reward_xp = maxi(int(values[3]), 0)
			entry.locked = bool(values[4])
	_recipes_cooked.clear()
	for id in data.get("recipes", []):
		_recipes_cooked[StringName(id)] = true
	changed.emit()
