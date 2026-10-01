class_name FurnitureSprites
extends RefCounted
## Sprites dos móveis (arte v3), lidos de res://art/furniture/sprites.json.
##
## Cada sprite tem uma âncora: o pixel da textura que fica sobre o vértice da
## frente da pegada do móvel (onde o FurnitureView fica). A textura tem
## "density" pixels por pixel de mundo. Gerados por tools/sprites/ (ver README lá).

const MANIFEST_PATH := "res://art/furniture/sprites.json"
const SPRITE_DIR := "res://art/furniture"


## Um sprite pronto para desenhar: textura, âncora e escala de desenho.
class Sprite:
	extends RefCounted

	var texture: Texture2D
	## Âncora em pixels da textura.
	var anchor := Vector2.ZERO
	## Pixels de textura por pixel de mundo.
	var density := 1.0

	## Retângulo de desenho em coordenadas do nó (âncora na origem).
	func draw_rect() -> Rect2:
		return Rect2(-anchor / density, texture.get_size() / density)


static var _manifest: Dictionary = {}
static var _cache: Dictionary = {}  # nome do sprite -> Sprite


## Sprite do móvel nesta rotação (0 a 3), ou null se o móvel ainda não tem arte.
static func lookup(furniture_id: StringName, rotation_steps: int) -> Sprite:
	var manifest := _load_manifest()
	var rotations: Dictionary = manifest.get("furniture", {}).get(String(furniture_id), {})
	var sprite_name: String = rotations.get(str(posmod(rotation_steps, 4)), "")
	if sprite_name.is_empty():
		return null
	if _cache.has(sprite_name):
		return _cache[sprite_name]
	var info: Dictionary = manifest.get("sprites", {}).get(sprite_name, {})
	var path := SPRITE_DIR.path_join(sprite_name + ".png")
	if info.is_empty() or not ResourceLoader.exists(path):
		return null
	var sprite := Sprite.new()
	sprite.texture = load(path)
	var anchor: Array = info["anchor"]
	sprite.anchor = Vector2(anchor[0], anchor[1])
	sprite.density = float(manifest.get("density", 1.0))
	_cache[sprite_name] = sprite
	return sprite


static func _load_manifest() -> Dictionary:
	if _manifest.is_empty() and ResourceLoader.exists(MANIFEST_PATH):
		var json: JSON = load(MANIFEST_PATH)
		if json != null and json.data is Dictionary:
			_manifest = json.data
	return _manifest
