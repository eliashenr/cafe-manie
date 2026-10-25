class_name CityLights
extends RefCounted
## Nova York à noite (DT-080): funções prontas que a cidade e o café ligam conforme a escuridão.
## - A cor das luzes desenhadas (janelas acesas, poças de luz): compensada pelo NightTint, para a luz não escurecer
##   junto com o resto do mundo.
## - A luz dos postes da rua e a luz quente que sai do salão (PointLight2D, que clareiam o que está em volta).

## Abaixo disto, a noite ainda não começou (nada aceso).
const MIN_NIGHT := 0.02
## Janelas acesas: quanto aparecem no meio da noite.
const WINDOW_STRENGTH := 0.95
## Poste: cor, força e alcance da luz; a poça de luz desenhada no chão embaixo dele.
const LAMP_COLOR := Color(1.0, 0.76, 0.46)
const LAMP_ENERGY := 0.75
const LAMP_RADIUS := 170.0
const POOL_COLOR := Color(1.0, 0.8, 0.5, 0.42)
const POOL_SIZE := Vector2(190.0, 84.0)
## Luz quente do salão: espalha um pouco pela calçada, como a luz que sai das janelas.
const INTERIOR_COLOR := Color(1.0, 0.8, 0.55)
const INTERIOR_ENERGY := 0.75
const INTERIOR_MARGIN := 1.35


## Cor para desenhar uma luz com a escuridão [param night] e o NightTint de cor [param tint]: a cor dividida pela
## do NightTint (que vai multiplicar de novo) e a transparência acompanhando a noite.
static func glow_modulate(night: float, tint: Color, strength := WINDOW_STRENGTH) -> Color:
	return Color(1.0 / maxf(tint.r, 0.01), 1.0 / maxf(tint.g, 0.01), 1.0 / maxf(tint.b, 0.01), clampf(night, 0.0, 1.0) * strength)


## Luz do poste, posta na lanterna (desligada até a noite).
static func lamp_light() -> PointLight2D:
	var light := PointLight2D.new()
	light.name = "LampLight"
	light.texture = FxParticles.soft_dot()
	light.texture_scale = LAMP_RADIUS / (FxParticles.soft_dot().get_width() / 2.0)
	light.color = LAMP_COLOR
	light.enabled = false
	return light


## Luz quente do salão, do tamanho do café de [param grid_size] pisos (desligada até a noite).
static func interior_glow(grid_size: Vector2i) -> PointLight2D:
	var light := PointLight2D.new()
	light.name = "InteriorGlow"
	light.texture = FxParticles.soft_dot()
	light.color = INTERIOR_COLOR
	light.enabled = false
	fit_interior_glow(light, grid_size)
	return light


## Centraliza a luz do salão e ajusta o alcance ao tamanho do café (depois de uma expansão).
static func fit_interior_glow(light: PointLight2D, grid_size: Vector2i) -> void:
	var bounds := IsoProjection.grid_bounds(grid_size)
	light.position = bounds.get_center()
	light.texture_scale = bounds.size.x * INTERIOR_MARGIN / FxParticles.soft_dot().get_width()


## Liga, desliga e ajusta a força de uma luz conforme a escuridão.
static func set_light(light: PointLight2D, night: float, energy: float) -> void:
	light.enabled = night > MIN_NIGHT
	light.energy = energy * night
