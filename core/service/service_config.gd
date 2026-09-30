class_name ServiceConfig
extends Resource
## Parâmetros de balanceamento do atendimento (res://data/config/service.tres).
## Nenhum destes números é definitivo: são pontos de partida para testar (seção 85).

@export_group("Clientes")
## Intervalo base, em segundos, entre chegadas de clientes.
@export var spawn_interval := 10.0
## Variação aleatória do intervalo (0.3 = ±30%).
@export_range(0.0, 0.9) var spawn_jitter := 0.3
## Máximo de clientes dentro da cafeteria ao mesmo tempo.
@export var max_customers := 6
## Segundos que um cliente comum aceita esperar sentado até ser servido.
@export var customer_patience := 45.0
## Velocidade de caminhada, em pisos por segundo.
@export var customer_walk_speed := 2.2
## Segundos comendo antes de pagar.
@export var eat_time := 5.0
## XP por cliente servido.
@export var customer_xp := 3

@export_group("Garçom")
@export var waiter_walk_speed := 3.2
## Segundos para pegar o prato no balcão e para entregá-lo.
@export var handling_time := 0.5

@export_group("Popularidade")
## Popularidade inicial (0 a 100).
@export_range(0.0, 100.0) var popularity_start := 50.0
## Ganho máximo por cliente satisfeito (servido rápido ganha tudo; no limite da paciência, metade).
@export var popularity_gain := 1.5
## Perda por cliente que vai embora sem ser servido.
@export var popularity_loss := 4.0
## Multiplicador do intervalo de chegada com popularidade 0 (mais lento).
@export var spawn_multiplier_at_zero := 1.6
## Multiplicador do intervalo de chegada com popularidade 100 (mais rápido).
@export var spawn_multiplier_at_max := 0.6

@export_group("Beleza")
## Beleza total (móveis + revestimentos) que dá o bônus máximo.
@export var beauty_for_max_bonus := 200.0
## Paciência extra dos clientes com o bônus máximo (0.3 = +30%).
@export_range(0.0, 2.0) var beauty_patience_bonus := 0.3
## Redução do intervalo entre chegadas com o bônus máximo (0.25 = 25% mais rápido).
@export_range(0.0, 0.9) var beauty_spawn_bonus := 0.25

@export_group("Cozinha")
## Porções que cabem em um balcão.
@export var counter_capacity := 40


func is_valid() -> bool:
	return spawn_interval > 0.0 and max_customers > 0 and customer_patience > 0.0 \
		and customer_walk_speed > 0.0 and waiter_walk_speed > 0.0 and eat_time >= 0.0 \
		and handling_time >= 0.0 and counter_capacity > 0 and beauty_for_max_bonus > 0.0


## Intervalo médio entre chegadas para uma popularidade (0 a 100).
func spawn_interval_for(popularity: float) -> float:
	var t := clampf(popularity / 100.0, 0.0, 1.0)
	return spawn_interval * lerpf(spawn_multiplier_at_zero, spawn_multiplier_at_max, t)
