extends SceneTree
## Recorta as folhas da arte v3 e grava os sprites do jogo com a âncora de cada um.
##
## Uso (na pasta do projeto):
##   python tools/art_direction/v3/export_sprites.py     # desenha as folhas em tools/sprites/raw/
##   godot --headless -s res://tools/sprites/crop_sprites.gd
##
## O res://art/sprites/sprites.json guarda, para cada sprite, a âncora em pixels da textura
## e repassa o resto do manifesto (móveis por rotação, personagens, pratos).

const SOURCE_DIR := "res://tools/sprites/raw"
const TARGET_DIR := "res://art/sprites"


func _initialize() -> void:
	var source := _read_json(SOURCE_DIR.path_join("sprites.json"))
	if source.is_empty():
		printerr("Rode antes: python tools/art_direction/v3/export_sprites.py")
		quit(1)
		return
	_clear_target()
	var sheets := {}
	var sprites := {}
	var touching: Array[String] = []
	for sprite_name: String in source["sprites"]:
		var info: Dictionary = source["sprites"][sprite_name]
		var sheet_name: String = info["sheet"]
		if not sheets.has(sheet_name):
			var path := ProjectSettings.globalize_path(SOURCE_DIR.path_join(source["sheets"][sheet_name]))
			sheets[sheet_name] = Image.load_from_file(path)
		var sheet: Image = sheets[sheet_name]
		var rect := Rect2i(info["rect"][0], info["rect"][1], info["rect"][2], info["rect"][3])
		var cell := sheet.get_region(rect)
		var used := cell.get_used_rect()
		if used.size == Vector2i.ZERO:
			printerr("Figura vazia: ", sprite_name)
			quit(1)
			return
		if used.position.x == 0 or used.position.y == 0 or used.end.x == rect.size.x or used.end.y == rect.size.y:
			touching.append(sprite_name)
		cell.get_region(used).save_png(TARGET_DIR.path_join(sprite_name + ".png"))
		var anchor: Array = info["anchor"]
		sprites[sprite_name] = {
			"anchor": [snappedf(anchor[0] - rect.position.x - used.position.x, 0.01),
				snappedf(anchor[1] - rect.position.y - used.position.y, 0.01)],
		}
	if not touching.is_empty():
		printerr("Encostam na borda do espaço reservado (podem ter saído cortadas): ", ", ".join(touching))
		quit(1)
		return
	var manifest := source.duplicate()
	manifest.erase("sheets")
	manifest["sprites"] = sprites
	var file := FileAccess.open(TARGET_DIR.path_join("sprites.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, " ", false) + "\n")
	print("%d sprites em %s" % [sprites.size(), TARGET_DIR])
	quit(0)


## Apaga os PNGs antigos (um sprite que saiu do manifesto não pode ficar para trás).
func _clear_target() -> void:
	DirAccess.make_dir_recursive_absolute(TARGET_DIR)
	for file_name in DirAccess.get_files_at(TARGET_DIR):
		if file_name.ends_with(".png"):
			DirAccess.remove_absolute(TARGET_DIR.path_join(file_name))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
