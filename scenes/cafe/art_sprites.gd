class_name ArtSprites
extends RefCounted
## Sprites da arte v3 (móveis, personagens, pratos), lidos de res://art/sprites/sprites.json.
##
## Cada sprite tem uma âncora: o pixel da textura que fica no ponto de apoio
## (vértice da frente da pegada, para móveis e para quem está sentado; os pés,
## para quem está em pé; o centro, para pratos e carinhas). A textura tem
## "density" pixels por pixel de mundo. Gerados por tools/sprites/ (ver README lá).

const MANIFEST_PATH := "res://art/sprites/sprites.json"
const SPRITE_DIR := "res://art/sprites"


## Um sprite pronto para desenhar: textura, âncora e escala de desenho.
class Sprite:
	extends RefCounted

	var texture: Texture2D
	## Âncora em pixels da textura.
	var anchor := Vector2.ZERO
	## Pixels de textura por pixel de mundo.
	var density := 1.0

	## Retângulo de desenho em coordenadas do nó, com a âncora na origem e escala 1.
	func draw_rect() -> Rect2:
		return rect_at(Vector2.ZERO)

	## Retângulo de desenho com a âncora no ponto dado, na escala dada.
	func rect_at(point: Vector2, scale := 1.0) -> Rect2:
		return Rect2(point - anchor / density * scale, texture.get_size() / density * scale)

	## Tamanho em pixels de mundo, em escala 1.
	func world_size() -> Vector2:
		return texture.get_size() / density


static var _manifest: Dictionary = {}
static var _cache: Dictionary = {}  # nome do sprite -> Sprite


## Sprite pelo nome (ex.: "cliente_03_frente_andar"), ou null se não existe.
static func get_sprite(sprite_name: String) -> Sprite:
	if _cache.has(sprite_name):
		return _cache[sprite_name]
	var manifest := _load_manifest()
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


## Sprite do móvel nesta rotação (0 a 3), ou null se o móvel ainda não tem arte.
static func furniture(furniture_id: StringName, rotation_steps: int) -> Sprite:
	var rotations: Dictionary = _load_manifest().get("furniture", {}).get(String(furniture_id), {})
	var sprite_name: String = rotations.get(str(posmod(rotation_steps, 4)), "")
	return null if sprite_name.is_empty() else get_sprite(sprite_name)


## Prato da receita, ou null se a receita ainda não tem arte.
static func food(recipe_id: StringName) -> Sprite:
	var sprite_name: String = _load_manifest().get("food", {}).get(String(recipe_id), "")
	return null if sprite_name.is_empty() else get_sprite(sprite_name)


## Panela da receita no fogão (com a chama acesa), ou null se não há arte.
static func cookware(recipe_id: StringName) -> Sprite:
	var sprite_name: String = _load_manifest().get("cookware", {}).get(String(recipe_id), "")
	return null if sprite_name.is_empty() else get_sprite(sprite_name)


## Forno aceso visto pela porta, nas rotações em que a frente do fogão aparece (0 e 3); senão null.
static func stove_glow(rotation_steps: int) -> Sprite:
	var sprite_name: String = _load_manifest().get("stove_glow", {}).get(str(posmod(rotation_steps, 4)), "")
	return null if sprite_name.is_empty() else get_sprite(sprite_name)


## Altura do tampo do balcão, em pixels de mundo, onde ficam as pilhas de pratos.
static func counter_top() -> float:
	return float(_load_manifest().get("counter_top", 0.0))


## Largura natural de um prato, em pixels de mundo (para escalar ao desenhar menor).
static func food_width() -> float:
	return float(_load_manifest().get("food_width", 64.0))


## Altura do tampo da mesa, em pixels de mundo (0 se não é mesa com arte).
static func table_top(furniture_id: StringName) -> float:
	return float(_load_manifest().get("table_tops", {}).get(String(furniture_id), 0.0))


## Dados dos personagens: "customers" (visuais de cliente), "waiter",
## "tray_food" (centro x, y e largura do prato na bandeja) e "seated_back_chair".
static func characters() -> Dictionary:
	return _load_manifest().get("characters", {})


## Piso do revestimento nesta célula: no xadrez, claro e escuro se alternam; nos
## outros, a variação sai da posição (sempre a mesma para a mesma célula).
static func floor_tile(surface_id: StringName, cell: Vector2i) -> Sprite:
	var info: Dictionary = _load_manifest().get("floors", {}).get(String(surface_id), {})
	var names: Array = info.get("sprites", [])
	if names.is_empty():
		return null
	var index := posmod(cell.x + cell.y, 2) if info.get("mode", "") == "xadrez" else posmod(cell.x * 7 + cell.y * 13 + cell.x * cell.y, names.size())
	return get_sprite(names[mini(index, names.size() - 1)])


## Tapete da entrada (por cima do piso).
static func floor_entrance() -> Sprite:
	return get_sprite(_load_manifest().get("floor_entrance", ""))


## Painel de uma célula da parede: "R" (direita, ao longo de x) ou "L" (esquerda, ao longo de y).
static func wall_panel(surface_id: StringName, side: String) -> Sprite:
	var sprite_name: String = _load_manifest().get("walls", {}).get(String(surface_id), {}).get(side, "")
	return null if sprite_name.is_empty() else get_sprite(sprite_name)


## Nome do enfeite da célula [param index] da parede (contando do canto do fundo),
## ou "" se ela fica lisa. Ex.: "janela", "relogio".
static func wall_decoration_name(side: String, index: int) -> String:
	var cycle: Array = _load_manifest().get("wall_decorations", {}).get(side, [])
	return "" if cycle.is_empty() else cycle[posmod(index, cycle.size())]


## Enfeite da célula [param index] da parede, ou null.
static func wall_decoration(side: String, index: int) -> Sprite:
	var deco := wall_decoration_name(side, index)
	return null if deco.is_empty() else get_sprite("enfeite_%s_%s" % [deco, side])


## Altura da parede da arte, em pixels de mundo (0 se não há arte de parede).
static func wall_height() -> float:
	return float(_load_manifest().get("wall_height", 0.0))


## Peças do exterior: "lawn" e "asphalt" (texturas de repetir), "lawn_world" e
## "asphalt_world" (período delas em pixels de mundo), "lamp" e "flower_bed".
static func exterior() -> Dictionary:
	return _load_manifest().get("exterior", {})


static func _load_manifest() -> Dictionary:
	if _manifest.is_empty() and ResourceLoader.exists(MANIFEST_PATH):
		var json: JSON = load(MANIFEST_PATH)
		if json != null and json.data is Dictionary:
			_manifest = json.data
	return _manifest
