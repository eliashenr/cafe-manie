class_name FxMaterials
extends RefCounted
## Materiais dos efeitos visuais: shaders leves de canvas_item (uma leitura de textura por pixel),
## compatíveis com o renderer mobile. Cada chamada cria um material novo, para cada nó ter os seus
## parâmetros (cor do brilho, pontos de foco).

const SILHOUETTE := preload("res://art/shaders/silhouette.gdshader")
const GLOW := preload("res://art/shaders/glow_halo.gdshader")
const FADE := preload("res://art/shaders/fade_near_points.gdshader")
## Quantos pontos de foco o shader de esmaecimento aceita.
const MAX_FOCUS := 8


static func silhouette(tint: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SILHOUETTE
	material.set_shader_parameter("tint", tint)
	return material


static func glow(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GLOW
	material.set_shader_parameter("glow_color", color)
	return material


static func fade(radius: float, min_alpha: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = FADE
	material.set_shader_parameter("radius", radius)
	material.set_shader_parameter("min_alpha", min_alpha)
	set_focus(material, PackedVector2Array())
	return material


## Troca os pontos de foco do esmaecimento (os que passarem de MAX_FOCUS ficam de fora).
static func set_focus(material: ShaderMaterial, points: PackedVector2Array) -> void:
	var padded := PackedVector2Array()
	padded.resize(MAX_FOCUS)
	var count := mini(points.size(), MAX_FOCUS)
	for i in count:
		padded[i] = points[i]
	material.set_shader_parameter("focus", padded)
	material.set_shader_parameter("focus_count", count)
