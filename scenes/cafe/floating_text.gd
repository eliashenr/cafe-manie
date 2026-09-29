class_name FloatingText
extends Node2D
## Texto que sobe e some sobre o mundo: "+3 ouro", "+6 porções".
## Resposta visual imediata às ações importantes (seção 123).

const RISE := 42.0
const DURATION := 1.2
const FONT_SIZE := 18

var text := ""
var color := Color.WHITE


static func spawn(parent: Node, world_position: Vector2, message: String, tint: Color) -> FloatingText:
	var floating := FloatingText.new()
	floating.text = message
	floating.color = tint
	floating.position = world_position
	floating.z_index = 20
	parent.add_child(floating)
	return floating


func _ready() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - RISE, DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, DURATION).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var at := Vector2(-width / 2.0, 0.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 4, Color(0.1, 0.06, 0.04, 0.8))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
