class_name MasteryConfig
extends Resource
## Domínio das receitas (res://data/config/mastery.tres, DT-053): quantas vezes tirar a receita pronta do fogão
## para ganhar cada estrela, e o prêmio de cada uma.

## Pratos prontos para cada estrela (crescente). O tamanho define quantas estrelas existem.
@export var thresholds: PackedInt32Array = [5, 20, 60]
## Ouro de cada estrela, em vezes o custo dos ingredientes da receita.
@export var gold_multipliers: PackedFloat32Array = [2.0, 4.0, 8.0]
## XP de cada estrela, em vezes o XP da receita.
@export var xp_multipliers: PackedFloat32Array = [1.0, 2.0, 4.0]


func is_valid() -> bool:
	if thresholds.is_empty() or thresholds.size() != gold_multipliers.size() or thresholds.size() != xp_multipliers.size():
		return false
	for i in thresholds.size():
		if thresholds[i] <= 0 or (i > 0 and thresholds[i] <= thresholds[i - 1]):
			return false
	return true


func max_stars() -> int:
	return thresholds.size()
