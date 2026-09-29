class_name ExpansionPlan
extends Resource
## Etapas de expansão da cafeteria (res://data/config/expansions.tres).
## Cada etapa: [code]{"size": Vector2i(10, 8), "level": 2, "price": 150}[/code].
## As etapas precisam crescer (nunca diminuir) em relação à anterior.

@export var steps: Array[Dictionary] = []


func is_valid() -> bool:
	var previous := Vector2i.ZERO
	for step in steps:
		var size: Vector2i = step.get("size", Vector2i.ZERO)
		if size.x < previous.x or size.y < previous.y or size == previous:
			return false
		if int(step.get("level", 0)) < 1 or int(step.get("price", -1)) < 0:
			return false
		previous = size
	return true


## Próxima etapa maior que o tamanho atual, ou {} se não houver mais.
func next_after(current_size: Vector2i) -> Dictionary:
	for step in steps:
		var size: Vector2i = step["size"]
		if size.x >= current_size.x and size.y >= current_size.y and size != current_size:
			return step
	return {}
