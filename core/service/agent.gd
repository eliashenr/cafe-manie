class_name Agent
extends RefCounted
## Personagem que anda pelo grid (cliente ou garçom).
##
## A posição é em células, com o centro da célula (x, y) em Vector2(x, y).
## O movimento é por tick(delta), só enquanto o jogo está aberto.

## Identificador único, para a interface ligar cada personagem à sua vista.
var serial := 0
var position := Vector2.ZERO
## Pisos que ainda faltam percorrer, em ordem.
var path: Array[Vector2i] = []
## Metas do último caminho pedido, para recalcular se o layout mudar.
var goals: Array[Vector2i] = []
## Pisos por segundo.
var speed := 2.0
## Última direção de movimento (para a arte saber para onde olhar).
var facing := Vector2(0, 1)


func cell() -> Vector2i:
	return Vector2i(roundi(position.x), roundi(position.y))


func is_moving() -> bool:
	return not path.is_empty()


## Define o caminho a seguir. O primeiro piso é descartado se for onde o agente já está.
func follow(new_path: Array[Vector2i], new_goals: Array[Vector2i]) -> void:
	path = new_path.duplicate()
	goals = new_goals.duplicate()
	if not path.is_empty() and Vector2(path[0]) == position:
		path.remove_at(0)


func stop() -> void:
	path.clear()
	goals.clear()


## Anda pelo caminho. Retorna true quando não há mais caminho (chegou).
func advance(delta: float) -> bool:
	var budget := speed * delta
	while budget > 0.0 and not path.is_empty():
		var target := Vector2(path[0])
		var distance := position.distance_to(target)
		if distance > 0.0:
			facing = (target - position) / distance
		if distance <= budget:
			position = target
			budget -= distance
			path.remove_at(0)
		else:
			position += (target - position) / distance * budget
			budget = 0.0
	return path.is_empty()


## Pisos que o agente ocupa agora: onde está e para onde está indo.
func occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = [cell()]
	if not path.is_empty() and not cells.has(path[0]):
		cells.append(path[0])
	return cells
