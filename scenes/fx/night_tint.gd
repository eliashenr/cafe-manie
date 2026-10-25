class_name NightTint
extends CanvasModulate
## Noite no café (DT-064): escurece o salão, a rua e a cidade (o HUD fica de fora, numa CanvasLayer) conforme a
## escuridão da NightConfig. As luzes das luminárias (PointLight2D nos móveis) brilham por cima.

## Cor no meio da noite: o azul da noite de Nova York (DT-080); o salão fica quente com a luz dele.
const NIGHT_COLOR := Color(0.36, 0.43, 0.74)

## Escuridão atual (0 de dia, 1 no meio da noite).
var amount := 0.0


func _init() -> void:
	name = "NightTint"
	color = Color.WHITE


func set_amount(value: float) -> void:
	if is_equal_approx(value, amount):
		return
	amount = clampf(value, 0.0, 1.0)
	color = Color.WHITE.lerp(NIGHT_COLOR, amount)
