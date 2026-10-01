extends SceneTree
## Recorta os PNGs crus da arte v3 e grava os sprites do jogo com a âncora de cada um.
##
## Uso (na pasta do projeto):
##   python tools/art_direction/v3/export_sprites.py     # desenha e gera tools/sprites/raw/
##   godot --headless -s res://tools/sprites/crop_sprites.gd
##
## O res://art/furniture/sprites.json guarda, para cada sprite, a âncora em pixels da textura
## (o vértice da frente da pegada do móvel) e, para cada móvel, o sprite de cada rotação.

const SOURCE_DIR := "res://tools/sprites/raw"
const TARGET_DIR := "res://art/furniture"


func _initialize() -> void:
	var source := _read_json(SOURCE_DIR.path_join("sprites.json"))
	if source.is_empty():
		printerr("Rode antes: python tools/art_direction/v3/export_sprites.py")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(TARGET_DIR)
	var sprites := {}
	for sprite_name: String in source["sprites"]:
		var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE_DIR.path_join(sprite_name + ".png")))
		if image == null:
			printerr("PNG não encontrado: ", sprite_name)
			quit(1)
			return
		var used := image.get_used_rect()
		image.get_region(used).save_png(TARGET_DIR.path_join(sprite_name + ".png"))
		var anchor: Array = source["sprites"][sprite_name]["anchor"]
		sprites[sprite_name] = {
			"anchor": [snappedf(anchor[0] - used.position.x, 0.01), snappedf(anchor[1] - used.position.y, 0.01)],
		}
	var manifest := {"density": source["density"], "sprites": sprites, "furniture": source["furniture"]}
	var file := FileAccess.open(TARGET_DIR.path_join("sprites.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, " ", false) + "\n")
	print("%d sprites em %s" % [sprites.size(), TARGET_DIR])
	quit(0)


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
