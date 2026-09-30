class_name AchievementDefinition
extends Resource
## Conquista progressiva (res://data/achievements, seção 49). Cada degrau
## tem um título, uma meta no contador e uma recompensa em Café Ouro.

@export var id: StringName
## Posição na lista (menor vem antes).
@export var order := 0
## Contador de PlayerStats que a conquista acompanha.
@export var stat: StringName
## O que medir, para a tela: "clientes servidos", "pratos preparados"...
@export var description := ""
## Um título por degrau, do mais fácil ao mais difícil.
@export var tier_titles: Array[String] = []
## Meta de cada degrau (crescente).
@export var tier_targets: Array[int] = []
## Café Ouro de cada degrau.
@export var tier_rewards: Array[int] = []


func is_valid() -> bool:
	if id == &"" or stat == &"" or tier_targets.is_empty():
		return false
	if tier_titles.size() != tier_targets.size() or tier_rewards.size() != tier_targets.size():
		return false
	var previous := 0
	for target in tier_targets:
		if target <= previous:
			return false
		previous = target
	return tier_rewards.all(func(reward: int) -> bool: return reward >= 0)


func tier_count() -> int:
	return tier_targets.size()
