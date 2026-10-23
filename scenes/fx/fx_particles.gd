class_name FxParticles
extends RefCounted
## Partículas leves por CPU (CPUParticles2D): rodam em qualquer Android, sem depender da GPU.
## A única textura é uma bolinha suave feita de gradiente (art/fx/soft_dot.tres).

## Vapor dos fogões: poucas bolinhas que sobem, crescem e somem.
const STEAM_AMOUNT := 7
const STEAM_LIFETIME := 1.7
const STEAM_COLOR := Color(1.0, 1.0, 1.0, 0.55)
## Comida estragada (DT-055): o mesmo vapor, verde e mais lento.
const STINK_COLOR := Color(0.55, 0.72, 0.22, 0.6)
const STINK_SPEED := 0.55
## Notas do show no palco (DT-066).
const NOTES_AMOUNT := 8
const NOTES_LIFETIME := 2.2
## Pagamento: confete dourado que estoura e cai, mais umas faíscas.
const CONFETTI_AMOUNT := 18
const SPARK_AMOUNT := 10
const BURST_LIFETIME := 0.9
const GOLDS: Array[Color] = [Color("ffd23f"), Color("ffb400"), Color("fff3a0"), Color("f08c00")]

## Bolinha branca de borda suave, 32x32 (gradiente radial, sem imagem).
const SOFT_DOT := preload("res://art/fx/soft_dot.tres")


static func soft_dot() -> Texture2D:
	return SOFT_DOT


## Vapor contínuo (ligue e desligue com emitting).
static func steam() -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.name = "Steam"
	particles.amount = STEAM_AMOUNT
	particles.lifetime = STEAM_LIFETIME
	particles.preprocess = STEAM_LIFETIME
	particles.texture = soft_dot()
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 4.0
	particles.direction = Vector2(0, -1)
	particles.spread = 14.0
	particles.gravity = Vector2(0, -10)
	particles.initial_velocity_min = 12.0
	particles.initial_velocity_max = 22.0
	particles.scale_amount_min = 0.35
	particles.scale_amount_max = 0.55
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.5))
	grow.add_point(Vector2(1.0, 1.5))
	particles.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, STEAM_COLOR)
	fade.set_color(1, Color(STEAM_COLOR, 0.0))
	particles.color_ramp = fade
	return particles


## Fumaça verde da comida estragada no fogão (ligue e desligue com emitting).
static func stink() -> CPUParticles2D:
	var particles := steam()
	particles.name = "Stink"
	particles.lifetime = STEAM_LIFETIME / STINK_SPEED
	particles.preprocess = particles.lifetime
	particles.initial_velocity_min *= STINK_SPEED
	particles.initial_velocity_max *= STINK_SPEED
	particles.spread = 30.0
	var fade := Gradient.new()
	fade.set_color(0, STINK_COLOR)
	fade.set_color(1, Color(STINK_COLOR, 0.0))
	particles.color_ramp = fade
	return particles


## Notas musicais que sobem do palco durante o show (DT-066; ligue e desligue com emitting).
static func notes(texture: Texture2D) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.name = "Notes"
	particles.amount = NOTES_AMOUNT
	particles.lifetime = NOTES_LIFETIME
	particles.preprocess = NOTES_LIFETIME  # o show já começa com notas no ar
	particles.texture = texture
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 40.0
	particles.direction = Vector2(0, -1)
	particles.spread = 35.0
	particles.gravity = Vector2(0, -20)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 50.0
	particles.scale_amount_min = 0.25
	particles.scale_amount_max = 0.4
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	particles.color_ramp = fade
	return particles


## Estouro de confete dourado e faíscas em [param at] (some sozinho quando acaba).
static func gold_burst(parent: Node, at: Vector2) -> Node2D:
	var burst := Node2D.new()
	burst.name = "GoldBurst"
	burst.position = at
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	colors.colors = PackedColorArray(GOLDS)
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.add_point(0.7, Color.WHITE)
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	# Confete: quadradinhos (sem textura, a partícula é um quadrado do tamanho da escala) que giram e caem.
	var confetti := CPUParticles2D.new()
	confetti.name = "Confetti"
	confetti.amount = CONFETTI_AMOUNT
	confetti.lifetime = BURST_LIFETIME
	confetti.one_shot = true
	confetti.explosiveness = 0.95
	confetti.direction = Vector2(0, -1)
	confetti.spread = 70.0
	confetti.gravity = Vector2(0, 320)
	confetti.initial_velocity_min = 110.0
	confetti.initial_velocity_max = 190.0
	confetti.angular_velocity_min = -540.0
	confetti.angular_velocity_max = 540.0
	confetti.scale_amount_min = 3.5
	confetti.scale_amount_max = 6.0
	confetti.color_initial_ramp = colors
	confetti.color_ramp = fade
	burst.add_child(confetti)
	# Faíscas: bolinhas claras que se espalham e somem rápido.
	var sparks := CPUParticles2D.new()
	sparks.name = "Sparks"
	sparks.amount = SPARK_AMOUNT
	sparks.lifetime = BURST_LIFETIME * 0.6
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.texture = soft_dot()
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 50.0
	sparks.initial_velocity_max = 110.0
	sparks.scale_amount_min = 0.25
	sparks.scale_amount_max = 0.45
	sparks.color = Color("fff3a0")
	sparks.color_ramp = fade
	burst.add_child(sparks)
	parent.add_child(burst)
	confetti.emitting = true
	sparks.emitting = true
	confetti.finished.connect(burst.queue_free)
	return burst
