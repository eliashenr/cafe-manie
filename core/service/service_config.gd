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
## Segundos olhando o cardápio depois de sentar, antes de pedir.
@export var order_think_time := 1.5
## Chance de pedir qualquer prato do cardápio (as receitas liberadas), mesmo o que não está no balcão.
## Sem nada no balcão, todo mundo pede do cardápio.
@export_range(0.0, 1.0) var menu_order_chance := 0.4
## No cardápio, os pratos rápidos saem mais: o peso de cada receita é 1 / (tempo de preparo ^ este número).
## 0 = todos com a mesma chance.
@export_range(0.0, 2.0) var menu_cook_time_weight := 0.5
## Quanto da paciência se gasta enquanto o prato pedido está no fogão (0.5 = metade).
@export_range(0.0, 1.0) var patience_drain_while_cooking := 0.5
## Cada nível acima do 1 encurta o intervalo entre chegadas (0.06 = 6% por nível)...
@export_range(0.0, 0.5) var spawn_speedup_per_level := 0.06
## ...até esta fração do intervalo.
@export_range(0.1, 1.0) var spawn_level_floor := 0.45
## Clientes a mais dentro da cafeteria por nível acima do 1.
@export var extra_customers_per_level := 1.0
## Cliente satisfeito (missões): servido antes de a paciência cair desta fração.
@export_range(0.0, 1.0) var happy_patience := 0.5

@export_group("Fila")
## Quantos esperam na calçada quando não há cadeira livre (0 = sem fila).
@export var queue_capacity := 5
## Segundos que aceitam esperar na fila.
@export var queue_patience := 30.0
## Perda de popularidade por quem desiste da fila.
@export var queue_popularity_loss := 1.5
## Onde fica o primeiro da fila, a partir da entrada (em pisos: +x é a calçada), e o passo entre um e outro.
@export var queue_offset := Vector2(2.6, 0.0)
@export var queue_spacing := Vector2(0.0, 0.9)

@export_group("Garçom")
@export var waiter_walk_speed := 3.2
## Segundos para pegar o prato no balcão e para entregá-lo.
@export var handling_time := 0.5
## Segundos (em média) parado perto de um fogão ou balcão antes de ir para outro, quando não há o que fazer.
@export var waiter_idle_pause := 3.0

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
		and handling_time >= 0.0 and counter_capacity > 0 and beauty_for_max_bonus > 0.0 \
		and order_think_time >= 0.0 and queue_capacity >= 0 and queue_patience > 0.0 and waiter_idle_pause >= 0.0


## Intervalo médio entre chegadas para uma popularidade (0 a 100).
func spawn_interval_for(popularity: float) -> float:
	var t := clampf(popularity / 100.0, 0.0, 1.0)
	return spawn_interval * lerpf(spawn_multiplier_at_zero, spawn_multiplier_at_max, t)


## Fração do intervalo entre chegadas no nível (quanto maior o nível, mais gente).
func level_spawn_factor(level: int) -> float:
	return maxf(spawn_level_floor, 1.0 - spawn_speedup_per_level * (level - 1))


## Máximo de clientes dentro da cafeteria no nível.
func max_customers_at(level: int) -> int:
	return max_customers + floori(extra_customers_per_level * (level - 1))
