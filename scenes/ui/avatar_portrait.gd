class_name AvatarPortrait
extends Control
## Retrato do avatar do chef (DT-070): as camadas (roupa, cabeça e chapéu) desenhadas pela âncora de cada uma,
## para encaixarem mesmo depois de a arte ser recortada.

## Caixa comum das camadas na arte (px da interface): largura, altura e onde fica a âncora.
const BOX := Vector2(140, 170)
const ANCHOR := Vector2(70, 110)

## Nomes dos sprites, de baixo para cima.
var layers: Array[String] = []:
	set(value):
		layers = value
		queue_redraw()


func _draw() -> void:
	var scale := minf(size.x / BOX.x, size.y / BOX.y)
	var origin := (size - BOX * scale) / 2.0 + ANCHOR * scale
	for layer in layers:
		var sprite := ArtSprites.get_sprite(layer)
		if sprite != null:
			draw_texture_rect(sprite.texture, sprite.rect_at(origin, scale), false)


## Nomes das camadas para estas peças ({Slot: AvatarPartDefinition}).
static func layer_names(parts: Dictionary) -> Array[String]:
	var skin: AvatarPartDefinition = parts[AvatarPartDefinition.Slot.SKIN]
	var hair: AvatarPartDefinition = parts[AvatarPartDefinition.Slot.HAIR]
	var hat: AvatarPartDefinition = parts[AvatarPartDefinition.Slot.HAT]
	var outfit: AvatarPartDefinition = parts[AvatarPartDefinition.Slot.OUTFIT]
	return ["avatar_roupa_" + outfit.art, "avatar_cabeca_%s_%s" % [skin.art, hair.art], "avatar_chapeu_" + hat.art]
