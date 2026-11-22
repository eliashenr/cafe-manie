class_name AvatarPortrait
extends Control
## O chef aprovado usa a pintura inteira; outras combinações mantêm as camadas originais da DT-070.

const BOX := Vector2(140, 170)
const ANCHOR := Vector2(70, 110)
const APPROVED_LAYERS: Array[String] = ["avatar_roupa_branca", "avatar_cabeca_clara_curto_castanho", "avatar_chapeu_toque"]


class LegacyLayers:
	extends Control

	var layers: Array[String] = []


	## Mesma textura, ordem, escala e âncora do renderer original; estes são os comandos desenhados.
	func draw_commands() -> Array[Dictionary]:
		var commands: Array[Dictionary] = []
		var scale := minf(size.x / AvatarPortrait.BOX.x, size.y / AvatarPortrait.BOX.y)
		var origin := (size - AvatarPortrait.BOX * scale) / 2.0 + AvatarPortrait.ANCHOR * scale
		for layer in layers:
			var sprite := ArtSprites.get_sprite(layer)
			if sprite != null:
				commands.append({"texture": sprite.texture, "rect": sprite.rect_at(origin, scale)})
		return commands


	func _draw() -> void:
		for command in draw_commands():
			draw_texture_rect(command["texture"], command["rect"], false)


## Nomes e ordem usados pelo diálogo, HUD e saves existentes.
var layers: Array[String] = []:
	set(value):
		var changed := layers != value
		layers = value.duplicate()
		if is_node_ready():
			_sync_layers()
			if changed:
				react()

## Apenas a prévia grande anima a combinação aprovada. Variantes, cards e HUD são estáticos.
var animated := false:
	set(value):
		animated = value
		if is_node_ready():
			_approved.animated = animated and uses_approved_chef()

var _canvas: LegacyLayers
var _approved: ChefAnimatedPortrait


func _ready() -> void:
	_canvas = LegacyLayers.new()
	_canvas.name = "Layers"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.resized.connect(_canvas.queue_redraw)
	_approved = ChefAnimatedPortrait.new()
	_approved.name = "ApprovedChef"
	_approved.animated = false
	_approved.visible = false
	add_child(_approved)
	_approved.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# O botão do diálogo recebe o toque; miniaturas não interceptam compras.
	_approved.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_layers()


func _sync_layers() -> void:
	_canvas.layers = layers.duplicate()
	_canvas.queue_redraw()
	var approved := uses_approved_chef()
	_canvas.visible = not approved
	_approved.visible = approved
	_approved.animated = animated and approved


func uses_approved_chef() -> bool:
	return layers == APPROVED_LAYERS


## Resposta visual local; não compra, equipa nem altera o estado da partida.
func react() -> void:
	if is_node_ready() and uses_approved_chef():
		_approved.react()


## Cores dos botões de pele; a arte das variantes continua vindo de ArtSprites.
static func skin_color(skin: String) -> Color:
	match skin:
		"morena_clara": return Color("ca9169")
		"parda": return Color("a66a46")
		"negra": return Color("73452f")
		_: return Color("e8a678")


## Nomes das camadas para estas peças ({Slot: AvatarPartDefinition}).
static func layer_names(parts: Dictionary) -> Array[String]:
	var skin: AvatarPartDefinition = parts[AvatarPartDefinition.Slot.SKIN]
	var hair: AvatarPartDefinition = parts[AvatarPartDefinition.Slot.HAIR]
	var hat: AvatarPartDefinition = parts[AvatarPartDefinition.Slot.HAT]
	var outfit: AvatarPartDefinition = parts[AvatarPartDefinition.Slot.OUTFIT]
	return ["avatar_roupa_" + outfit.art, "avatar_cabeca_%s_%s" % [skin.art, hair.art], "avatar_chapeu_" + hat.art]
