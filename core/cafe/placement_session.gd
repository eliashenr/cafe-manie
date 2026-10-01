class_name PlacementSession
extends RefCounted
## Estado do modo de construção: "estou posicionando um móvel".
##
## Serve tanto para um móvel novo quanto para mover um existente. Nada muda
## no layout até confirm(). Cancelar é só descartar a sessão, então não
## existe estado a restaurar.

var layout: CafeLayout
var definition: FurnitureDefinition
var rotation := 0
var target := CafeGrid.NO_CELL
## Id do móvel sendo movido, ou &"" quando é um móvel novo.
var moving_id: StringName = &""


static func for_new(on_layout: CafeLayout, new_definition: FurnitureDefinition) -> PlacementSession:
	var session := PlacementSession.new()
	session.layout = on_layout
	session.definition = new_definition
	return session


## Sessão para mover um móvel já posicionado; começa na posição atual dele.
## Retorna null se o id não existir.
static func for_move(on_layout: CafeLayout, id: StringName) -> PlacementSession:
	var placement := on_layout.get_placement(id)
	if placement == null:
		return null
	var session := PlacementSession.new()
	session.layout = on_layout
	session.definition = placement.definition
	session.rotation = placement.rotation
	session.target = placement.origin
	session.moving_id = id
	return session


func is_moving() -> bool:
	return moving_id != &""


func footprint() -> Vector2i:
	return CafeLayout.rotated_footprint(definition.footprint, rotation)


## Escolhe o piso. Uma cadeira levada para o lado de uma mesa já vira para ela
## (girar no mesmo piso continua valendo; ela só se ajeita quando muda de piso).
func set_target(cell: Vector2i) -> void:
	if cell != target and cell != CafeGrid.NO_CELL and CafeLayout.turns_toward_tables(definition):
		var toward := layout.rotation_toward_table(cell, rotation)
		if toward >= 0:
			rotation = toward
	target = cell


func rotate_clockwise() -> void:
	rotation = (rotation + 1) % 4


func check() -> CafeLayout.Check:
	if target == CafeGrid.NO_CELL:
		return CafeLayout.Check.NO_TARGET
	return layout.check_placement(definition, target, rotation, moving_id)


func can_confirm() -> bool:
	return check() == CafeLayout.Check.OK


## Aplica no layout. Retorna o id do móvel posicionado, ou &"" se a posição for inválida.
func confirm() -> StringName:
	if not can_confirm():
		return &""
	if is_moving():
		return moving_id if layout.move(moving_id, target, rotation) == CafeLayout.Check.OK else &""
	return layout.place(definition, target, rotation)
