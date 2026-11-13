extends "res://tools/art_sample.gd"
## Conferência: enfeites no café. Variante "enf:<lote>".

const GROUPS := [
	["plant_pot", "banana_tree", "bonsai", "cactus", "olive_tree", "macrame_plant", "succulents", "tree_blueberry", "tree_mango", "tree_strawberry", "flower_vase", "floor_lamp"],
	["edison_lamp", "paper_lantern", "paris_lamp", "neon_diner", "station_clock", "arcade", "claw_machine", "jukebox", "boombox", "disco_ball", "balloons", "party_cake"],
	["pinata", "popcorn_cart", "ring_toss", "critic_statue", "cupcake_tree", "chocolate_fountain", "giant_pumpkin", "hay_bale", "wagon_wheel", "wine_barrel", "eiffel", "parrot"],
	["lava_lamp", "trophy_bronze", "trophy_silver", "trophy_gold", "machine_coffee", "machine_coffee_smart", "machine_juice", "machine_frozen", "train_locomotive", "train_wagon", "train_dining", "witch_cauldron"],
	["bookshelf", "dj_booth", "stage", "delivery_counter"],
]

var _stoves: Array = []


func _dress(simulation, variant: String) -> void:
	var batch := int(variant.split(":")[1])
	var catalog = load("res://core/furniture/furniture_catalog.gd").load_from()
	var layout = simulation.layout
	var free: Array[Vector2i] = []
	for y in [2, 3, 5, 7, 1]:
		for x in 8:
			if (x + y) % 2 == 0:
				free.append(Vector2i(x, y))
	for id in GROUPS[batch]:
		var ok := false
		var tries: Array[Vector2i] = free.duplicate()
		for cell in tries:
			var placed: StringName = layout.place(catalog.get_definition(StringName(id)), cell, 0)
			if placed != &"":
				free.erase(cell)
				ok = true
				if String(id).begins_with("train") or id == "witch_cauldron":
					_stoves.append(placed)
				break
		if not ok:
			print("sem lugar: ", id)


func _populate(simulation) -> void:
	var lasagna = simulation.recipes.get_definition(&"lasagna")
	for id in _stoves:
		simulation.kitchen.restore_stove(id, lasagna, simulation.clock.now() - lasagna.cook_time * 0.5)
