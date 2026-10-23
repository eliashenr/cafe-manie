class_name DirtConfig
extends Resource
## Chão sujo (DT-068, res://data/config/dirt.tres): às vezes quem termina de comer deixa uma mancha do lado da
## cadeira; um toque limpa e dá um pouco de ouro e XP. Enquanto houver manchas, a popularidade cai aos poucos.

## Chance de quem terminou de comer deixar uma mancha.
@export_range(0.0, 1.0) var spot_chance := 0.2
## Máximo de manchas ao mesmo tempo.
@export var max_spots := 5
## Ouro e XP por mancha limpa.
@export var clean_gold := 5
@export var clean_xp := 2
## Segundos de café aberto com o chão sujo entre uma perda de popularidade e a próxima.
@export var popularity_interval := 60.0
## Popularidade perdida a cada intervalo, por mancha.
@export var popularity_loss_per_spot := 0.5


func is_valid() -> bool:
	return spot_chance >= 0.0 and spot_chance <= 1.0 and max_spots > 0 and clean_gold >= 0 and clean_xp >= 0 \
		and popularity_interval > 0.0 and popularity_loss_per_spot >= 0.0
