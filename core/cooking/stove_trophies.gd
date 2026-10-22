class_name StoveTrophies
extends RefCounted
## Troféus aceleradores (DT-057): um troféu deixa mais rápidos os fogões nas 8 casas em volta dele. Cada prato que
## ele acelera gasta uma carga; sem cargas, ele para de acelerar até ser renovado com Café Ouro. Guardado, ele
## lembra as cargas que tinha (quem o põe de volta recebe as mesmas); vendido, elas somem.

## As cargas de um troféu mudaram (gastou, renovou, guardou).
signal changed

var layout: CafeLayout
## id do troféu na cafeteria -> pratos que ainda acelera. Sem entrada = cheio.
var _charges := {}
## id da definição -> cargas dos troféus guardados no inventário (uma por troféu guardado).
var _stored := {}


func _init(cafe_layout: CafeLayout) -> void:
	layout = cafe_layout
	layout.changed.connect(_forget_removed)


## O móvel é um troféu acelerador?
func is_trophy(id: StringName) -> bool:
	var placement := layout.get_placement(id)
	return placement != null and placement.definition.is_trophy()


## Pratos que o troféu ainda acelera (0 = gasto).
func charges_left(id: StringName) -> int:
	var placement := layout.get_placement(id)
	if placement == null or not placement.definition.is_trophy():
		return 0
	return int(_charges.get(id, placement.definition.trophy_dishes))


func is_worn_out(id: StringName) -> bool:
	return is_trophy(id) and charges_left(id) <= 0


## O troféu que acelera este fogão (o mais forte com carga entre os das 8 casas em volta), ou &"".
func booster_for(stove_id: StringName) -> StringName:
	var stove := layout.get_placement(stove_id)
	if stove == null:
		return &""
	var stove_cells := CafeGrid.footprint_cells(stove.origin, CafeLayout.rotated_footprint(stove.definition.footprint, stove.rotation))
	var best: StringName = &""
	var best_bonus := 0.0
	for placement in layout.placements():
		if not placement.definition.is_trophy() or charges_left(placement.id) <= 0:
			continue
		var bonus := placement.definition.stove_speed_bonus
		if bonus > best_bonus or (bonus == best_bonus and best != &"" and String(placement.id) < String(best)):
			if _touches(placement, stove_cells):
				best = placement.id
				best_bonus = bonus
	return best


## Quanto mais rápido o fogão cozinha agora (0.25 = 25% menos tempo; 0 sem troféu).
func speed_bonus(stove_id: StringName) -> float:
	var trophy := booster_for(stove_id)
	return layout.get_placement(trophy).definition.stove_speed_bonus if trophy != &"" else 0.0


## Gasta uma carga do troféu (um prato acelerado). Retorna true se ele acabou de se gastar.
func use(id: StringName) -> bool:
	var left := charges_left(id)
	if left <= 0:
		return false
	_charges[id] = left - 1
	changed.emit()
	return left - 1 == 0


## Volta o troféu às cargas cheias.
func renew(id: StringName) -> void:
	_charges.erase(id)
	changed.emit()


## O troféu vai para o inventário: as cargas dele ficam guardadas junto.
func store(id: StringName) -> void:
	var placement := layout.get_placement(id)
	if placement == null or not placement.definition.is_trophy():
		return
	var pool: Array = _stored.get(placement.definition.id, [])
	pool.append(charges_left(id))
	_stored[placement.definition.id] = pool
	_charges.erase(id)
	changed.emit()


## Um troféu guardado voltou para a cafeteria com o id novo [param id]: recebe as cargas que tinha.
func place_stored(id: StringName) -> void:
	var placement := layout.get_placement(id)
	if placement == null or not placement.definition.is_trophy():
		return
	var pool: Array = _stored.get(placement.definition.id, [])
	if pool.is_empty():
		return
	_charges[id] = int(pool.pop_back())
	if pool.is_empty():
		_stored.erase(placement.definition.id)
	changed.emit()


func to_data() -> Dictionary:
	var charges := {}
	for id: StringName in _charges:
		charges[String(id)] = _charges[id]
	var stored := {}
	for definition_id: StringName in _stored:
		stored[String(definition_id)] = _stored[definition_id].duplicate()
	return {"charges": charges, "stored": stored}


func restore(data: Dictionary) -> void:
	_charges.clear()
	_stored.clear()
	var charges: Dictionary = data.get("charges", {}) if data.get("charges") is Dictionary else {}
	for id in charges:
		_charges[StringName(id)] = maxi(int(charges[id]), 0)
	var stored: Dictionary = data.get("stored", {}) if data.get("stored") is Dictionary else {}
	for definition_id in stored:
		var pool: Array = []
		for value in (stored[definition_id] if stored[definition_id] is Array else []):
			pool.append(maxi(int(value), 0))
		if not pool.is_empty():
			_stored[StringName(definition_id)] = pool
	changed.emit()


## Encosta no fogão? Alguma casa do troféu fica a 1 casa (de lado ou na diagonal) de alguma casa do fogão.
func _touches(trophy: CafeLayout.Placement, stove_cells: Array[Vector2i]) -> bool:
	for cell in CafeGrid.footprint_cells(trophy.origin, CafeLayout.rotated_footprint(trophy.definition.footprint, trophy.rotation)):
		for stove_cell in stove_cells:
			if maxi(absi(cell.x - stove_cell.x), absi(cell.y - stove_cell.y)) == 1:
				return true
	return false


## Defesa: troféu que sumiu do layout sem passar por store() perde as cargas (foi vendido).
func _forget_removed() -> void:
	for id: StringName in _charges.keys():
		if layout.get_placement(id) == null:
			_charges.erase(id)
