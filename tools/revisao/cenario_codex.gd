extends "res://tools/revisao/visual_codex.gd"
## DT-106: café completo por coleção, incluindo cozinha, revestimentos, janelas e porta.
## Somente dados em memória; nunca usa SaveService. C troca a coleção, N troca dia/noite.
## -Extra colecoes fotografa o mostruário e as 12 coleções; colecao:japao fotografa só Japão.

const ORNAMENT_SLOTS: Array[String] = ["left:7", "top:3"]
var _base_ornaments: Dictionary = {}


func _dress(simulation, variant: String) -> void:
	super(simulation, variant)
	for segment in ORNAMENT_SLOTS:
		_base_ornaments[segment] = simulation.style.wall_item_at(segment)
	# Três janelas visíveis na amostra inicial, sem retirar os pontos de iluminação.
	for segment: String in ["left:1", "left:4", "top:5"]:
		simulation.style._wall_items[segment] = &"janela"


func _set_overview_camera() -> void:
	# A reforma inclui o alto das paredes e a cozinha; o enquadramento precisa mostrá-los.
	_cafe.camera.zoom = Vector2.ONE * 0.9
	_cafe.camera.global_position = IsoProjection.grid_bounds(Vector2i(8, 8)).get_center() - Vector2(0, 52)
	_cafe.camera.force_update_scroll()


func _apply_collection(index: int) -> bool:
	if not super(index):
		return false
	var collection := COLLECTIONS[index]
	var simulation = _cafe.simulation
	var categories := [FurnitureDefinition.Category.COOKING, FurnitureDefinition.Category.COUNTER,
		FurnitureDefinition.Category.DECOR]
	for category in categories:
		var choices: Array = []
		for definition: FurnitureDefinition in simulation.furniture.all():
			if definition.collection == collection and definition.category == category \
					and definition.footprint == Vector2i.ONE:
				choices.append(definition)
		if choices.is_empty():
			continue
		var next := 0
		for placement in _cafe.layout.placements():
			if placement.definition.category == category and placement.definition.footprint == Vector2i.ONE:
				var replacement: FurnitureDefinition = choices[next % choices.size()]
				if placement.definition.id != replacement.id:
					# No jogo os IDs têm definições estáveis. Esta troca de amostra precisa
					# recriar a vista para não herdar luzes/selos do enfeite anterior.
					var old_view = _cafe.world_layer.view_for(placement.id)
					if old_view != null:
						_cafe.world_layer._views.erase(placement.id)
						_cafe.world_layer.remove_child(old_view)
						old_view.queue_free()
					placement.definition = replacement
				next += 1
	# Aplicar só a aparência diretamente evita recompensas de reforma na ferramenta de revisão.
	var style = simulation.style
	for kind in [SurfaceDefinition.Kind.FLOOR, SurfaceDefinition.Kind.WALL]:
		for surface: SurfaceDefinition in simulation.surfaces.all(kind):
			if surface.collection != collection:
				continue
			if kind == SurfaceDefinition.Kind.FLOOR:
				style.floor_id = surface.id
				style._floor_cells.clear()
			else:
				style.wall_id = surface.id
				style._wall_cells.clear()
			break
	var windows: Array[WallItemDefinition] = []
	var ornaments: Array[WallItemDefinition] = []
	for item: WallItemDefinition in simulation.wall_items.all():
		if item.collection == collection:
			if item.lets_light_in:
				windows.append(item)
			else:
				ornaments.append(item)
	for i in 3:
		if not windows.is_empty():
			style._wall_items[["left:1", "left:4", "top:5"][i]] = windows[i % windows.size()].id
	# Coleções sem enfeite próprio usam a base, nunca o objeto deixado pela coleção anterior.
	for segment in ORNAMENT_SLOTS:
		style._wall_items.erase(segment)
		if _base_ornaments.get(segment, &"") != &"":
			style._wall_items[segment] = _base_ornaments[segment]
	if not ornaments.is_empty():
		for i in 2:
			style._wall_items[ORNAMENT_SLOTS[i]] = ornaments[i % ornaments.size()].id
	for door: DoorDefinition in simulation.doors.all():
		if door.collection == collection:
			style.door_id = door.id
			break
	_cafe._apply_style()
	# O mostruário troca o conjunto pronto; não iniciar animação de compra numa captura pausada.
	var previously_synced: bool = _cafe.world_layer._synced_once
	_cafe.world_layer._synced_once = false
	_cafe.world_layer.sync()
	_cafe.world_layer._synced_once = previously_synced
	_cafe.world_layer.refresh(simulation)
	_cafe._apply_night()
	_cafe.hud.refresh()
	return true


func _set_review_title(batch: int) -> void:
	super(batch)
	root.title = root.title.replace("Revisão Visual", "Revisão do Cenário")


func _capture_suite() -> void:
	for _frame in WARMUP_FRAMES:
		await process_frame
	_show_overview(0)
	await create_timer(Juice.FADE_IN_TIME + 0.15).timeout
	if not await _write_capture(_output):
		quit(1)
		return
	if _request == "colecoes":
		for index in COLLECTIONS.size():
			if not _apply_collection(index):
				quit(1)
				return
			for _frame in 8:
				await process_frame
			var output := _output.get_basename() + "_" + String(COLLECTIONS[index]) + ".png"
			if not await _write_capture(output):
				quit(1)
				return
	print("CENARIO CODEX OK: ", _written, " capturas | ", _output)
	quit(0)
