extends "res://tools/art_sample.gd"
## Conferência: todas as cadeiras da loja com gente sentada. Variante "cadeiras:<lote>:<rotação>".

const PER_BATCH := 12

var _seats: Array = []


func _dress(simulation, variant: String) -> void:
	var parts := variant.split(":")
	var batch := int(parts[1])
	var rotation := int(parts[2])
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/sprites/sprites.json"))
	var ids: Array = manifest["chair_backrests"].keys()
	var catalog = load("res://core/furniture/furniture_catalog.gd").load_from()
	var chosen := ids.slice(batch * PER_BATCH, (batch + 1) * PER_BATCH)
	var layout = simulation.layout
	var cell := Vector2i(0, 2)
	for id in chosen:
		while cell.y < 8:
			var placed: StringName = layout.place(catalog.get_definition(StringName(id)), cell, rotation)
			var here := cell
			cell.x += 2
			if cell.x >= 8:
				cell = Vector2i((cell.y + 1) % 2, cell.y + 1)
			if placed != &"":
				_seats.append([here, placed])
				print(id, " em ", here)
				break


func _populate(simulation) -> void:
	var regular = load("res://data/customers/regular.tres")
	var serial := 10
	for seat in _seats:
		var customer = load("res://core/service/customer.gd").new()
		customer.serial = serial
		serial += 1
		customer.type = regular
		customer.seat_id = seat[1]
		customer.seat_cell = seat[0]
		customer.position = Vector2(seat[0])
		customer.state = 2
		customer.patience_total = 100.0
		customer.patience_left = 100.0
		customer.eat_left = 1000.0
		customer.order = simulation.recipes.get_definition(&"coffee")
		simulation.customers.append(customer)
