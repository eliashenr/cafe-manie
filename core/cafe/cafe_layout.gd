class_name CafeLayout
extends RefCounted
## Móveis posicionados na cafeteria e as regras de onde cada um pode ficar.
##
## Regras de posicionamento, na ordem em que são checadas:
## 1. um móvel em uso (fogão cozinhando, cadeira com cliente...) não sai do lugar;
## 2. o móvel inteiro cabe no grid;
## 3. não sobrepõe outro móvel;
## 4. não ocupa a entrada;
## 5. não cai em cima de alguém andando;
## 6. ninguém fica sem acesso: todo móvel com needs_access precisa de uma
##    célula vizinha alcançável a partir da entrada, andando só por pisos livres.
##
## Toda operação recusada não altera nada.

## Emitido sempre que um móvel é colocado, movido, girado ou removido.
signal changed

enum Check {
	OK,
	NO_TARGET,          ## nenhuma célula escolhida ainda
	OUT_OF_BOUNDS,      ## parte do móvel ficaria fora do grid
	OCCUPIED,           ## sobrepõe outro móvel
	BLOCKS_ENTRANCE,    ## ocuparia a entrada
	NO_ACCESS,          ## o próprio móvel ficaria sem acesso
	BLOCKS_ACCESS,      ## deixaria outro móvel sem acesso
	UNKNOWN_PLACEMENT,  ## id de móvel posicionado inexistente
	IN_USE,             ## o móvel está sendo usado agora
	AGENT_IN_THE_WAY,   ## tem cliente ou garçom passando nessas células
}

const NEIGHBORS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


## Um móvel posicionado. Leitura livre; altere só pelos métodos do CafeLayout.
class Placement:
	extends RefCounted

	var id: StringName
	var definition: FurnitureDefinition
	var origin: Vector2i
	## Quartos de volta no sentido horário (0 a 3).
	var rotation: int

	func footprint() -> Vector2i:
		return CafeLayout.rotated_footprint(definition.footprint, rotation)

	func cells() -> Array[Vector2i]:
		return CafeGrid.footprint_cells(origin, footprint())


var grid: CafeGrid
var entrance: Vector2i

## Opcional. Recebe um id e diz se o móvel está em uso agora. Quem sabe disso
## é a simulação do atendimento, que preenche este campo.
var in_use_provider: Callable
## Opcional. Retorna um Dictionary cujas chaves são as células (Vector2i)
## ocupadas por personagens neste instante.
var agent_cells_provider: Callable

var _placements: Dictionary = {}  # StringName -> Placement
var _next_serial := 1


func _init(grid_size: Vector2i, entrance_cell: Vector2i) -> void:
	grid = CafeGrid.new(grid_size)
	assert(grid.is_inside(entrance_cell), "A entrada precisa estar dentro do grid.")
	entrance = entrance_cell


## Entrada padrão: meio da borda da frente (x máximo), por onde os clientes chegam.
static func default_entrance(grid_size: Vector2i) -> Vector2i:
	return Vector2i(grid_size.x - 1, grid_size.y / 2)


## Em rotações ímpares a largura e a profundidade trocam de lugar.
static func rotated_footprint(footprint: Vector2i, rotation: int) -> Vector2i:
	return footprint if posmod(rotation, 2) == 0 else Vector2i(footprint.y, footprint.x)


func placements() -> Array[Placement]:
	var result: Array[Placement] = []
	result.assign(_placements.values())
	return result


func get_placement(id: StringName) -> Placement:
	return _placements.get(id)


func placement_at(cell: Vector2i) -> Placement:
	return _placements.get(grid.occupant_at(cell))


func count() -> int:
	return _placements.size()


## Número usado no próximo id gerado. O save guarda isto para os ids continuarem únicos.
func next_serial() -> int:
	return _next_serial


## Aumenta a cafeteria. Só cresce (nunca corta móveis). Se a largura aumentar,
## a entrada acompanha a borda da frente, na mesma fileira; a coluna nova é
## sempre livre, então a entrada nova também é.
func expand_to(new_size: Vector2i) -> bool:
	var old_size := grid.size
	if new_size.x < old_size.x or new_size.y < old_size.y or new_size == old_size:
		return false
	if not grid.resize(new_size):
		return false
	if new_size.x != old_size.x:
		entrance = Vector2i(new_size.x - 1, entrance.y)
	changed.emit()
	return true


# --- Save ------------------------------------------------------------------

## Recoloca um móvel salvo com o id original. Confere só limites e sobreposição:
## o layout salvo já tinha passado por todas as regras. Retorna false se não couber.
func restore_placement(id: StringName, definition: FurnitureDefinition, origin: Vector2i, rotation: int) -> bool:
	if id == &"" or _placements.has(id) or definition == null:
		return false
	var footprint := rotated_footprint(definition.footprint, rotation)
	if not grid.place(id, origin, footprint):
		return false
	var placement := Placement.new()
	placement.id = id
	placement.definition = definition
	placement.origin = origin
	placement.rotation = posmod(rotation, 4)
	_placements[id] = placement
	changed.emit()
	return true


## Garante que ids novos não colidam com os restaurados.
func restore_next_serial(value: int) -> void:
	_next_serial = maxi(_next_serial, value)


func is_in_use(id: StringName) -> bool:
	return id != &"" and in_use_provider.is_valid() and in_use_provider.call(id)


## Diz se o móvel pode ser removido agora.
func can_remove(id: StringName) -> Check:
	if not _placements.has(id):
		return Check.UNKNOWN_PLACEMENT
	return Check.IN_USE if is_in_use(id) else Check.OK


## Diz se o móvel pode ficar nessa posição. [param ignore_id] é o móvel que
## está sendo movido: as células dele contam como livres.
func check_placement(definition: FurnitureDefinition, origin: Vector2i, rotation: int,
		ignore_id: StringName = &"") -> Check:
	if is_in_use(ignore_id):
		return Check.IN_USE
	var cells := CafeGrid.footprint_cells(origin, rotated_footprint(definition.footprint, rotation))
	for cell in cells:
		if not grid.is_inside(cell):
			return Check.OUT_OF_BOUNDS
	for cell in cells:
		var occupant := grid.occupant_at(cell)
		if occupant != &"" and occupant != ignore_id:
			return Check.OCCUPIED
	if cells.has(entrance):
		return Check.BLOCKS_ENTRANCE
	if agent_cells_provider.is_valid():
		var agent_cells: Dictionary = agent_cells_provider.call()
		for cell in cells:
			if agent_cells.has(cell):
				return Check.AGENT_IN_THE_WAY

	# Simula o layout com o móvel na nova posição e confere o acesso de todos.
	var blocked: Dictionary = {}
	for placement: Placement in _placements.values():
		if placement.id != ignore_id:
			for cell in placement.cells():
				blocked[cell] = true
	for cell in cells:
		blocked[cell] = true
	var reachable := _reachable_from_entrance(blocked)

	if definition.needs_access and not _touches(cells, reachable):
		return Check.NO_ACCESS
	for placement: Placement in _placements.values():
		if placement.id != ignore_id and placement.definition.needs_access \
				and not _touches(placement.cells(), reachable):
			return Check.BLOCKS_ACCESS
	return Check.OK


## Posiciona um móvel novo. Retorna o id gerado, ou &"" se a posição for inválida.
func place(definition: FurnitureDefinition, origin: Vector2i, rotation := 0) -> StringName:
	if check_placement(definition, origin, rotation) != Check.OK:
		return &""
	var placement := Placement.new()
	placement.id = _new_id(definition)
	placement.definition = definition
	placement.origin = origin
	placement.rotation = posmod(rotation, 4)
	grid.place(placement.id, origin, placement.footprint())
	_placements[placement.id] = placement
	changed.emit()
	return placement.id


## Move e/ou gira um móvel existente. Retorna o resultado da checagem.
func move(id: StringName, origin: Vector2i, rotation: int) -> Check:
	var placement := get_placement(id)
	if placement == null:
		return Check.UNKNOWN_PLACEMENT
	var result := check_placement(placement.definition, origin, rotation, id)
	if result != Check.OK:
		return result
	grid.remove(id)
	placement.origin = origin
	placement.rotation = posmod(rotation, 4)
	grid.place(id, origin, placement.footprint())
	changed.emit()
	return Check.OK


func remove(id: StringName) -> bool:
	if can_remove(id) != Check.OK:
		return false
	grid.remove(id)
	_placements.erase(id)
	changed.emit()
	return true


## Id novo e único. Mesmo que o contador esteja atrasado (save antigo ou com
## defeito), nunca repete um id existente: isso sobrescreveria um móvel.
func _new_id(definition: FurnitureDefinition) -> StringName:
	var id := StringName("%s#%d" % [definition.id, _next_serial])
	while _placements.has(id):
		_next_serial += 1
		id = StringName("%s#%d" % [definition.id, _next_serial])
	_next_serial += 1
	return id


## Pisos livres alcançáveis a partir da entrada (busca em largura, 4 direções).
func _reachable_from_entrance(blocked: Dictionary) -> Dictionary:
	var reachable: Dictionary = {}
	if blocked.has(entrance):
		return reachable
	reachable[entrance] = true
	var frontier: Array[Vector2i] = [entrance]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step in NEIGHBORS:
			var next := cell + step
			if grid.is_inside(next) and not blocked.has(next) and not reachable.has(next):
				reachable[next] = true
				frontier.append(next)
	return reachable


## Se alguma das células tem um vizinho alcançável.
static func _touches(cells: Array[Vector2i], reachable: Dictionary) -> bool:
	for cell in cells:
		for step in NEIGHBORS:
			if reachable.has(cell + step):
				return true
	return false
