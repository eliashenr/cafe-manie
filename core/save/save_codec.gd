class_name SaveCodec
extends RefCounted
## Converte o estado do jogo em dados simples (para JSON) e de volta.
##
## O que é salvo: layout (móveis com os ids originais e tamanho da cafeteria),
## cozinha (receita e horário de início de cada fogão; porções de cada balcão),
## carteira, XP, popularidade, inventário e missões. Personagens não são salvos: ao voltar, a cafeteria reabre
## vazia, e as porções que estavam reservadas para pedidos voltam ao balcão.
##
## Todo save tem save_version (seção 64). Mudou o formato? Aumente
## CURRENT_VERSION e acrescente um passo em migrations().

## Histórico: 1 = primeira versão; 2 = acrescenta inventário e missões;
## 3 = acrescenta revestimentos (piso e parede), contadores, conquistas e recompensa diária.
const CURRENT_VERSION := 3


## Resultado de decode(): a simulação (null se os dados forem inutilizáveis)
## e avisos sobre partes ignoradas (ex.: um móvel que não existe mais).
class DecodeResult:
	extends RefCounted
	var simulation: CafeSimulation
	var warnings: Array[String] = []
	var saved_at := 0.0


# --- Gravar ----------------------------------------------------------------

static func encode(simulation: CafeSimulation) -> Dictionary:
	var layout := simulation.layout
	var placements: Array[Dictionary] = []
	for placement in layout.placements():
		placements.append({
			"id": String(placement.id),
			"furniture": String(placement.definition.id),
			"origin": _vec_to_array(placement.origin),
			"rotation": placement.rotation,
		})
	var kitchen: Dictionary = simulation.kitchen.to_data()
	kitchen["counters"] = _with_reserved_servings(kitchen["counters"], simulation)
	return {
		"save_version": CURRENT_VERSION,
		"saved_at": simulation.clock.now(),
		"layout": {
			"size": _vec_to_array(layout.grid.size),
			"entrance": _vec_to_array(layout.entrance),
			"next_serial": layout.next_serial(),
			"placements": placements,
		},
		"kitchen": kitchen,
		"wallet": simulation.wallet.to_data(),
		"xp": simulation.progression.xp,
		"popularity": simulation.popularity,
		"inventory": simulation.inventory.to_data(),
		"missions": simulation.missions.to_data(),
		"style": simulation.style.to_data(),
		"stats": simulation.stats.to_data(),
		"achievements": simulation.achievements.to_data(),
		"daily": simulation.daily.to_data(),
	}


## Soma de volta ao balcão de origem as porções reservadas para pedidos em andamento.
static func _with_reserved_servings(counters: Array, simulation: CafeSimulation) -> Array:
	var by_id := {}
	for entry: Dictionary in counters:
		by_id[entry["id"]] = entry
	for reserved in simulation.reserved_servings():
		var counter_id := String(reserved["counter_id"])
		var recipe_id := String(reserved["recipe"].id)
		var entry: Dictionary = by_id.get(counter_id, {})
		if entry.is_empty():
			by_id[counter_id] = {"id": counter_id, "recipe": recipe_id, "servings": 1}
		elif entry["recipe"] == recipe_id and entry["servings"] < simulation.config.counter_capacity:
			entry["servings"] += 1
		# Senão o balcão já tem outra receita: a porção se perde (caso raro, aceitável).
	return by_id.values()


# --- Ler -------------------------------------------------------------------

## Monta a simulação a partir de dados já migrados para CURRENT_VERSION.
static func decode(data: Dictionary, clock: GameClock, random_seed := 0) -> DecodeResult:
	var result := DecodeResult.new()
	if int(data.get("save_version", -1)) != CURRENT_VERSION:
		result.warnings.append("Versão de save inesperada: %s" % data.get("save_version"))
		return result
	var layout_data: Dictionary = _dict(data.get("layout"))
	var size := _array_to_vec(layout_data.get("size"))
	var entrance := _array_to_vec(layout_data.get("entrance"))
	if size.x <= 0 or size.y <= 0 or entrance.x < 0 or entrance.x >= size.x or entrance.y < 0 or entrance.y >= size.y:
		result.warnings.append("Layout do save inválido")
		return result
	result.saved_at = float(data.get("saved_at", 0.0))

	var furniture := FurnitureCatalog.load_from()
	var layout := CafeLayout.new(size, entrance)
	for entry in _list(layout_data.get("placements")):
		var placement: Dictionary = _dict(entry)
		var definition := furniture.get_definition(StringName(str(placement.get("furniture", ""))))
		var ok := definition != null and layout.restore_placement(StringName(str(placement.get("id", ""))),
			definition, _array_to_vec(placement.get("origin")), int(placement.get("rotation", 0)))
		if not ok:
			result.warnings.append("Móvel ignorado: %s" % placement)
	layout.restore_next_serial(int(layout_data.get("next_serial", 1)))

	var simulation := CafeSimulation.with_game_data(clock, layout, furniture, random_seed)
	var kitchen_data: Dictionary = _dict(data.get("kitchen"))
	for entry in _list(kitchen_data.get("stoves")):
		var stove: Dictionary = _dict(entry)
		var recipe := simulation.recipes.get_definition(StringName(str(stove.get("recipe", ""))))
		if not simulation.kitchen.restore_stove(StringName(str(stove.get("id", ""))), recipe, float(stove.get("started_at", 0.0))):
			result.warnings.append("Preparo ignorado: %s" % stove)
	for entry in _list(kitchen_data.get("counters")):
		var counter: Dictionary = _dict(entry)
		var recipe := simulation.recipes.get_definition(StringName(str(counter.get("recipe", ""))))
		if not simulation.kitchen.restore_counter(StringName(str(counter.get("id", ""))), recipe, int(counter.get("servings", 0))):
			result.warnings.append("Balcão ignorado: %s" % counter)

	simulation.wallet.restore(_dict(data.get("wallet")))
	simulation.progression.restore_xp(int(data.get("xp", 0)))
	simulation.restore_popularity(float(data.get("popularity", simulation.config.popularity_start)))
	simulation.inventory.restore(_dict(data.get("inventory")))
	simulation.missions.restore(_dict(data.get("missions")))
	simulation.missions.refresh()
	_restore_style(simulation, _dict(data.get("style")), result)
	simulation.stats.restore(_dict(data.get("stats")))
	simulation.achievements.restore(_dict(data.get("achievements")))
	simulation.daily.restore(_dict(data.get("daily")))
	# Contadores de nível e beleza acompanham o estado carregado; degraus que um
	# save antigo já merecia são desbloqueados (e pagos) agora.
	simulation.record_progress_stats()
	simulation.achievements.refresh()
	result.simulation = simulation
	return result


## Revestimentos comprados e aplicados. Os iniciais continuam sempre do jogador;
## um revestimento que deixou de existir volta para o inicial.
static func _restore_style(simulation: CafeSimulation, data: Dictionary, result: DecodeResult) -> void:
	if data.is_empty():
		return
	var style := simulation.style
	var defaults: Array[StringName] = style.owned()
	style.restore(data)
	for id in defaults:
		style.own(id)
	for kind in [SurfaceDefinition.Kind.FLOOR, SurfaceDefinition.Kind.WALL]:
		var applied := simulation.surfaces.get_definition(style.current(kind))
		if applied == null or applied.kind != kind or not style.owns(applied.id):
			result.warnings.append("Revestimento ignorado: %s" % style.current(kind))
			applied = simulation.surfaces.default_for(kind)
		if applied != null:
			style.apply(applied)


# --- Versões ---------------------------------------------------------------

## Passos de migração: o índice 0 converte da versão 1 para a 2, o índice 1
## da 2 para a 3, e assim por diante.
static func migrations() -> Array[Callable]:
	return [_v1_to_v2, _v2_to_v3]


## Versão 2 acrescentou inventário e missões: saves antigos começam com eles vazios.
static func _v1_to_v2(data: Dictionary) -> Dictionary:
	data["inventory"] = {}
	data["missions"] = {"index": 0, "progress": 0}
	return data


## Versão 3 acrescentou revestimentos, contadores e conquistas: saves antigos
## ficam com os revestimentos iniciais e os contadores zerados.
static func _v2_to_v3(data: Dictionary) -> Dictionary:
	data["style"] = {}
	data["stats"] = {}
	data["achievements"] = {}
	data["daily"] = {}
	return data


## Leva os dados até [param target_version]. Retorna {} se o save for de uma
## versão mais nova que o jogo, não tiver versão ou faltar um passo.
static func migrate(data: Dictionary, target_version := CURRENT_VERSION, steps: Array[Callable] = migrations()) -> Dictionary:
	if not data.has("save_version"):
		return {}
	var migrated := data.duplicate(true)
	var version := int(migrated["save_version"])
	if version > target_version or version < 1:
		return {}
	while version < target_version:
		var step_index := version - 1
		if step_index >= steps.size():
			return {}
		migrated = steps[step_index].call(migrated)
		version += 1
		migrated["save_version"] = version
	return migrated


# --- Tipos simples -----------------------------------------------------------

static func _vec_to_array(value: Vector2i) -> Array:
	return [value.x, value.y]


static func _array_to_vec(value: Variant) -> Vector2i:
	if value is Array and value.size() == 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(-1, -1)


static func _dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func _list(value: Variant) -> Array:
	return value if value is Array else []
