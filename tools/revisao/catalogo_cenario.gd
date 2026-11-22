extends "res://tools/art_sample.gd"
## Conferência real de todos os itens de cenário, sem lista fixa que esqueça eventos.
## foto.ps1 -Variant cozinha:0:0 ou decoracao:0:0 (grupo:lote:rotação).
## Seis itens por página, sem save e sem interface cobrindo os modelos.

const PER_PAGE := 6
const PLACES: Array[Vector2i] = [Vector2i(1, 1), Vector2i(4, 1), Vector2i(1, 3),
	Vector2i(4, 3), Vector2i(1, 5), Vector2i(4, 5)]

var _catalog_items: Array = []
var _catalog_placed: Array = []
var _catalog_title := ""
var _catalog_count := 0


func _dress(simulation, variant: String) -> void:
	var parts := variant.split(":")
	var group := parts[0]
	var page := int(parts[1]) if parts.size() > 1 else 0
	var rotation := int(parts[2]) if parts.size() > 2 else 0
	assert(group in ["cozinha", "decoracao"] and page >= 0 and rotation in range(4))
	var kitchen_categories := [FurnitureDefinition.Category.COOKING,
		FurnitureDefinition.Category.COUNTER, FurnitureDefinition.Category.MACHINE]
	for definition: FurnitureDefinition in simulation.furniture.all():
		var kitchen: bool = definition.category in kitchen_categories or definition.delivery
		if (group == "cozinha" and kitchen) or (group == "decoracao" \
				and definition.category == FurnitureDefinition.Category.DECOR and not kitchen):
			_catalog_items.append(definition)
	assert(page * PER_PAGE < _catalog_items.size(), "Página fora do catálogo")
	for placement in simulation.layout.placements():
		simulation.layout.remove(placement.id)
	var names: Array[String] = []
	for index in range(page * PER_PAGE, mini((page + 1) * PER_PAGE, _catalog_items.size())):
		var definition: FurnitureDefinition = _catalog_items[index]
		var id: StringName = simulation.layout.place(definition, PLACES[index % PER_PAGE], rotation)
		assert(id != &"", "Item não coube no catálogo: " + String(definition.id))
		_catalog_placed.append([id, definition])
		names.append(definition.display_name)
	_catalog_title = "%s · página %d/%d · rotação %d\n%s" % [group.capitalize(), page + 1,
		ceili(float(_catalog_items.size()) / PER_PAGE), rotation, " · ".join(names)]
	print("CATALOGO ITENS: ", names)
	var style = simulation.style
	style._wall_items.clear()
	style.floor_id = &"floor_wood"
	style.wall_id = &"wall_cream"
	style._floor_cells.clear()
	style._wall_cells.clear()


func _populate(simulation) -> void:
	var lasagna = simulation.recipes.get_definition(&"lasagna")
	for entry: Array in _catalog_placed:
		var definition: FurnitureDefinition = entry[1]
		if definition.category == FurnitureDefinition.Category.COOKING:
			simulation.kitchen.restore_stove(entry[0], lasagna, simulation.clock.now() - lasagna.cook_time * 0.5)
		elif definition.category == FurnitureDefinition.Category.COUNTER:
			simulation.kitchen.restore_counter(entry[0], simulation.recipes.get_definition(&"coxinha"), 9)


func _process(_delta: float) -> bool:
	_catalog_count += 1
	if _catalog_count == 1:
		for window: Window in _cafe.find_children("*", "Window", true, false):
			window.hide()
		_cafe.get_node("GameHud").hide()
		_cafe.get_node("BuildBar").hide()
		var camera = _cafe.camera
		camera.zoom = Vector2.ONE * 1.02
		camera.global_position = IsoProjection.grid_bounds(Vector2i(8, 8)).get_center() - Vector2(0, 55)
		camera.force_update_scroll()
		var layer := CanvasLayer.new()
		root.add_child(layer)
		var label := Label.new()
		label.text = _catalog_title
		label.position = Vector2(20, 16)
		label.add_theme_color_override("font_color", UiTheme.TEXT)
		label.add_theme_color_override("font_shadow_color", UiTheme.PANEL)
		label.add_theme_constant_override("shadow_outline_size", 8)
		label.add_theme_font_size_override("font_size", 18)
		layer.add_child(label)
	if _catalog_count < 45:
		return false
	var result := root.get_texture().get_image().save_png(_output)
	if result != OK:
		printerr("ERROR: não foi possível gravar o catálogo: ", result)
		quit(1)
	else:
		print("CATALOGO CENARIO OK: ", _catalog_placed.size(), " itens | ", _output)
		quit(0)
	return true
