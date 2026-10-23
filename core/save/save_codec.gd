class_name SaveCodec
extends RefCounted
## Converte o estado do jogo em dados simples (para JSON) e de volta.
##
## O que é salvo: layout (móveis com os ids originais e tamanho da cafeteria),
## cozinha (receita e horário de início de cada fogão; porções de cada balcão),
## carteira, XP, popularidade, inventário, missões, quantos garçons foram contratados, se o café está fechado e a
## energia das máquinas de bebida e o domínio das receitas.
## Os personagens em si não são salvos: ao voltar, a cafeteria reabre vazia, e as porções que estavam
## reservadas para pedidos voltam ao balcão.
##
## Todo save tem save_version (seção 64). Mudou o formato? Aumente
## CURRENT_VERSION e acrescente um passo em migrations().

## Histórico: 1 = primeira versão; 2 = acrescenta inventário e missões;
## 3 = acrescenta revestimentos (piso e parede), contadores, conquistas,
## recompensa diária e nome da cafeteria; 4 = as cadeiras dos saves antigos
## viram para a mesa uma vez (com a arte, para onde a cadeira olha aparece);
## 5 = acrescenta quantos garçons a cafeteria contratou; 6 = revestimento pintado piso a piso e
## trecho a trecho de parede; 7 = itens de parede escolhidos pelo jogador (antes, enfeites fixos);
## 8 = missões diárias e semanais; 9 = placa ABERTO/FECHADO da porta; 10 = energia das máquinas de bebida;
## 11 = domínio das receitas.
const CURRENT_VERSION := 19

## Marca posta pela migração para a versão 7: o decode pendura os enfeites de sempre, para o save antigo
## continuar com a mesma cara. A marca não volta a ser gravada.
const LEGACY_WALL_ITEMS_KEY := "hang_legacy_wall_items"

## Marca posta pela migração para a versão 4: o decode vira as cadeiras e a marca
## não volta a ser gravada.
const TURN_SEATS_KEY := "turn_seats_toward_tables"


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
		"mission_boards": {"daily": simulation.daily_missions.to_data(), "weekly": simulation.weekly_missions.to_data()},
		"style": simulation.style.to_data(),
		"stats": simulation.stats.to_data(),
		"achievements": simulation.achievements.to_data(),
		"daily": simulation.daily.to_data(),
		"cafe_name": simulation.cafe_name,
		"waiters": simulation.waiters.size(),
		"closed": simulation.closed,
		"energy": simulation.energy.to_data(),
		"mastery": simulation.mastery.to_data(),
		"spices": simulation.spice_shelf.to_data(),
		"trophies": simulation.trophies.to_data(),
		"stove_sets": simulation.stove_sets.to_data(),
		"critic": simulation.critic_to_data(),
		"events": simulation.events_to_data(),
		"orchard": simulation.orchard.to_data(),
		"fruits": simulation.fruit_stock.to_data(),
		"attractions": simulation.attractions.to_data(),
		"dirt": simulation.dirt.to_data(),
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
	if data.get(TURN_SEATS_KEY, false):
		layout.turn_seats_toward_tables()

	var simulation := CafeSimulation.with_game_data(clock, layout, furniture, random_seed)
	var kitchen_data: Dictionary = _dict(data.get("kitchen"))
	for entry in _list(kitchen_data.get("stoves")):
		var stove: Dictionary = _dict(entry)
		var recipe := simulation.recipes.get_definition(StringName(str(stove.get("recipe", ""))))
		if not simulation.kitchen.restore_stove(StringName(str(stove.get("id", ""))), recipe, float(stove.get("started_at", 0.0)),
				int(stove.get("extra", 0)), float(stove.get("duration", -1.0)), int(stove.get("bonus", 0))):
			result.warnings.append("Preparo ignorado: %s" % stove)
	for entry in _list(kitchen_data.get("counters")):
		var counter: Dictionary = _dict(entry)
		var recipe := simulation.recipes.get_definition(StringName(str(counter.get("recipe", ""))))
		if not simulation.kitchen.restore_counter(StringName(str(counter.get("id", ""))), recipe, int(counter.get("servings", 0))):
			result.warnings.append("Balcão ignorado: %s" % counter)

	simulation.wallet.restore(_dict(data.get("wallet")))
	simulation.progression.restore_xp(int(data.get("xp", 0)))
	simulation.energy.set_level(simulation.progression.level, clock.now())
	simulation.energy.restore(_dict(data.get("energy")), clock.now())
	simulation.mastery.restore(_dict(data.get("mastery")))
	simulation.spice_shelf.restore(_dict(data.get("spices")))
	simulation.trophies.restore(_dict(data.get("trophies")))
	simulation.stove_sets.restore(_dict(data.get("stove_sets")))
	simulation.restore_critic(_dict(data.get("critic")))
	simulation.restore_events(_dict(data.get("events")))
	simulation.orchard.restore(_dict(data.get("orchard")))
	simulation.fruit_stock.restore(_dict(data.get("fruits")))
	simulation.attractions.restore(_dict(data.get("attractions")))
	simulation.dirt.restore(_list(data.get("dirt")))
	simulation.restore_popularity(float(data.get("popularity", simulation.config.popularity_start)))
	simulation.inventory.restore(_dict(data.get("inventory")))
	simulation.missions.restore(_dict(data.get("missions")))
	simulation.missions.refresh()
	_restore_style(simulation, _dict(data.get("style")), result)
	simulation.stats.restore(_dict(data.get("stats")))
	simulation.achievements.restore(_dict(data.get("achievements")))
	simulation.daily.restore(_dict(data.get("daily")))
	var boards := _dict(data.get("mission_boards"))
	var unlocked := simulation.recipes.unlocked_at(simulation.progression.level).size()
	simulation.daily_missions.restore(_dict(boards.get("daily")), simulation.progression.level, unlocked)
	simulation.weekly_missions.restore(_dict(boards.get("weekly")), simulation.progression.level, unlocked)
	simulation.refresh_mission_periods()  # salvo num dia (ou semana) que já passou: começa de novo
	simulation.restore_waiter_count(int(data.get("waiters", 1)))
	simulation.set_closed(bool(data.get("closed", false)))
	if data.get(LEGACY_WALL_ITEMS_KEY, false):
		simulation.hang_legacy_wall_items()
	var saved_name := str(data.get("cafe_name", ""))
	if not saved_name.is_empty() and not simulation.set_cafe_name(saved_name):
		result.warnings.append("Nome da cafeteria ignorado: %s" % saved_name)
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
				style.apply(applied)  # a base inválida vira a inicial (e a pintura dessa parte sai)
	# Porta que deixou de existir (ou que não é do jogador) vira a inicial (DT-067).
	var door := simulation.doors.get_definition(style.door_id)
	if door == null or not style.owns(door.id):
		if style.door_id != &"":
			result.warnings.append("Porta ignorada: %s" % style.door_id)
		var start := simulation.default_door()
		style.door_id = start.id if start != null else &""
	# Item de parede que deixou de existir sai da parede.
	for wall_segment: String in style.hung_items():
		if simulation.wall_items.get_definition(style.hung_items()[wall_segment]) == null:
			result.warnings.append("Item de parede ignorado: %s" % wall_segment)
			style.hang([wall_segment] as Array[String], &"")
	# Pintura com revestimento que deixou de existir (ou de outro tipo) volta para a base.
	for cell: Vector2i in style.painted_floor():
		var surface := simulation.surfaces.get_definition(style.painted_floor()[cell])
		if surface == null or surface.kind != SurfaceDefinition.Kind.FLOOR:
			result.warnings.append("Piso pintado ignorado: %s" % cell)
			style.paint_floor([cell] as Array[Vector2i], style.floor_id)
	for wall_segment: String in style.painted_walls():
		var surface := simulation.surfaces.get_definition(style.painted_walls()[wall_segment])
		if surface == null or surface.kind != SurfaceDefinition.Kind.WALL:
			result.warnings.append("Parede pintada ignorada: %s" % wall_segment)
			style.paint_walls([wall_segment] as Array[String], style.wall_id)


# --- Versões ---------------------------------------------------------------

## Passos de migração: o índice 0 converte da versão 1 para a 2, o índice 1
## da 2 para a 3, e assim por diante.
static func migrations() -> Array[Callable]:
	return [_v1_to_v2, _v2_to_v3, _v3_to_v4, _v4_to_v5, _v5_to_v6, _v6_to_v7, _v7_to_v8, _v8_to_v9, _v9_to_v10, _v10_to_v11, _v11_to_v12, _v12_to_v13, _v13_to_v14, _v14_to_v15, _v15_to_v16, _v16_to_v17, _v17_to_v18, _v18_to_v19]


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
	# Quem já jogava ganha um nome padrão (e pode trocar tocando nele), em vez de ser interrompido.
	data["cafe_name"] = CafeSimulation.DEFAULT_CAFE_NAME
	return data


## Versão 4: o formato não muda, mas as cadeiras dos saves antigos foram postas
## quando a rotação delas não aparecia. Elas viram para a mesa uma vez, no decode.
static func _v3_to_v4(data: Dictionary) -> Dictionary:
	data[TURN_SEATS_KEY] = true
	return data


## Versão 5 acrescentou a contratação de garçons: saves antigos têm o garçom que vinha com a cafeteria.
static func _v4_to_v5(data: Dictionary) -> Dictionary:
	data["waiters"] = 1
	return data


## Versão 7: os enfeites das paredes viraram itens do jogador. O save antigo ganha os de sempre (no decode).
static func _v6_to_v7(data: Dictionary) -> Dictionary:
	data[LEGACY_WALL_ITEMS_KEY] = true
	return data


## Versão 8 acrescentou as missões diárias e semanais: saves antigos começam o dia e a semana do zero.
static func _v7_to_v8(data: Dictionary) -> Dictionary:
	data["mission_boards"] = {}
	return data


## Versão 9 acrescentou a placa ABERTO/FECHADO: saves antigos abrem com o café aberto.
static func _v8_to_v9(data: Dictionary) -> Dictionary:
	data["closed"] = false
	return data


## Versão 10 acrescentou a energia das máquinas de bebida: saves antigos começam com ela cheia.
static func _v9_to_v10(data: Dictionary) -> Dictionary:
	data["energy"] = {}
	return data


## Versão 11 acrescentou o domínio das receitas: saves antigos começam sem estrelas.
static func _v10_to_v11(data: Dictionary) -> Dictionary:
	data["mastery"] = {}
	return data


## Versão 12 acrescentou a prateleira de temperos (DT-056): saves antigos começam sem nenhum.
static func _v11_to_v12(data: Dictionary) -> Dictionary:
	data["spices"] = {}
	return data


## Versão 13 acrescentou as cargas dos troféus (DT-057). Saves antigos não tinham troféus.
static func _v12_to_v13(data: Dictionary) -> Dictionary:
	data["trophies"] = {}
	return data


## Versão 14 acrescentou os prêmios dos multifogões (DT-060). Saves antigos não tinham multifogão.
static func _v13_to_v14(data: Dictionary) -> Dictionary:
	data["stove_sets"] = {}
	return data


## Versão 15 acrescentou o crítico (DT-061): saves antigos começam sem visita e sem estrela.
static func _v14_to_v15(data: Dictionary) -> Dictionary:
	data["critic"] = {}
	return data


## Versão 16 acrescentou os eventos com prazo (DT-063): saves antigos começam sem evento visto.
static func _v15_to_v16(data: Dictionary) -> Dictionary:
	data["events"] = {}
	return data


## Versão 17 acrescentou a plantação (DT-065): saves antigos começam sem pés de fruta crescendo e sem frutas.
static func _v16_to_v17(data: Dictionary) -> Dictionary:
	data["orchard"] = {}
	data["fruits"] = {}
	return data


## Versão 18 acrescentou o ouro das atrações (DT-066): saves antigos começam com as atrações vazias.
static func _v17_to_v18(data: Dictionary) -> Dictionary:
	data["attractions"] = {}
	return data


## Versão 19 acrescentou o chão sujo (DT-068): saves antigos começam com o chão limpo.
static func _v18_to_v19(data: Dictionary) -> Dictionary:
	data["dirt"] = []
	return data


## Versão 6 acrescentou a pintura piso a piso: saves antigos ficam só com o revestimento de base.
static func _v5_to_v6(data: Dictionary) -> Dictionary:
	var style: Dictionary = data.get("style", {}) if data.get("style") is Dictionary else {}
	style["floor_cells"] = []
	style["wall_cells"] = []
	data["style"] = style
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
