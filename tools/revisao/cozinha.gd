extends "res://tools/art_sample.gd"
## Conferência: fogões cozinhando e balcões com pratos. Variante "cozinha:<lote>:<rotação do fogão>".

const STOVES := ["stove_steel", "stove_mint", "stove_cream", "stove_yellow", "stove_black", "stove_copper", "stove_blue", "stove_arcade", "stove_disco", "stove_samba", "stove_wood", "stove_talavera", "stove_moon"]
const COUNTERS := ["counter_steel", "counter_wood", "counter_pastel", "counter_marble", "counter_tile", "counter_neon", "counter_red", "counter_groovy", "counter_arcade", "counter_samba", "counter_bistro", "counter_bamboo"]

var _stoves: Array = []
var _counters: Array = []


func _dress(simulation, variant: String) -> void:
	var parts := variant.split(":")
	var batch := int(parts[1])
	var rotation := int(parts[2])
	var catalog = load("res://core/furniture/furniture_catalog.gd").load_from()
	var layout = simulation.layout
	var free: Array[Vector2i] = []
	for y in [2, 3, 5, 7, 1]:
		for x in 8:
			if (x + y) % 2 == 0:
				free.append(Vector2i(x, y))
	var ids: Array = STOVES.slice(batch * 6, (batch + 1) * 6)
	ids.append_array(COUNTERS.slice(batch * 6, (batch + 1) * 6))
	for id in ids:
		while not free.is_empty():
			var cell: Vector2i = free.pop_front()
			var placed: StringName = layout.place(catalog.get_definition(StringName(id)), cell, rotation)
			if placed != &"":
				if String(id).begins_with("stove"):
					_stoves.append(placed)
				else:
					_counters.append(placed)
				break
	print("colocados: ", _stoves.size(), " + ", _counters.size())


func _populate(simulation) -> void:
	var recipes = simulation.recipes
	var clock = simulation.clock
	var lasagna = recipes.get_definition(&"lasagna")
	for id in _stoves:
		simulation.kitchen.restore_stove(id, lasagna, clock.now() - lasagna.cook_time * 0.5)
	for id in _counters:
		simulation.kitchen.restore_counter(id, recipes.get_definition(&"coxinha"), 9)
