class_name NightTint
extends CanvasModulate
## Noite no café (DT-064): escurece o salão, a rua e a cidade (o HUD fica de fora, numa CanvasLayer) conforme a
## escuridão da NightConfig. As luzes das luminárias (PointLight2D nos móveis) brilham por cima.

## Cor no meio da noite: o azul-marinho da rua da referência A (DT-091), que deixa o salão quente em destaque.
const NIGHT_COLOR := Color(0.2, 0.25, 0.42)

## Grupo dos balões e selos, que recebem a ui_compensation quando a escuridão muda.
const OVERLAY_GROUP := &"night_overlays"

## O que cancela o escurecimento agora: o que precisa continuar legível à noite (balões e selos) usa esta cor (DT-091).
static var ui_compensation := Color.WHITE

## Escuridão atual (0 de dia, 1 no meio da noite).
var amount := 0.0


func _init() -> void:
	name = "NightTint"
	color = Color.WHITE
	ui_compensation = Color.WHITE


func set_amount(value: float) -> void:
	if is_equal_approx(value, amount):
		return
	amount = clampf(value, 0.0, 1.0)
	color = Color.WHITE.lerp(NIGHT_COLOR, amount)
	ui_compensation = Color(1.0 / color.r, 1.0 / color.g, 1.0 / color.b)
	if is_inside_tree():
		get_tree().set_group(OVERLAY_GROUP, "modulate", ui_compensation)
