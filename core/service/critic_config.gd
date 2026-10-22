class_name CriticConfig
extends Resource
## Crítico gastronômico (DT-061, res://data/config/critic.tres): aparece uma vez por dia, a partir de um nível, e
## pede um prato da aba do livro que é o tema da semana. Servido rápido, deixa uma estrela na mesa que, tocada, dá
## ouro, XP e cupons (mais cupons com o café mais popular). Mal servido, vai embora e volta outro dia.

## Nível a partir do qual o crítico visita o café.
@export var first_level := 5
## Segundos de café aberto, no dia, até o crítico chegar.
@export var arrival_delay := 90.0
## Paciência do crítico, em vezes a do cliente comum (ele é exigente).
@export var patience_multiplier := 0.8
## Servido com pelo menos esta fração da paciência sobrando = servido rápido: deixa a estrela.
@export_range(0.0, 1.0) var quick_service := 0.5
@export var reward_gold := 120
@export var reward_gold_per_level := 12.0
@export var reward_xp := 30
@export var reward_xp_per_level := 3.0
## Cupons com popularidade 0 e com popularidade 100 (no meio, proporcional).
@export var coupons_at_zero := 1
@export var coupons_at_max := 5
## Abas do livro que são o tema de cada semana, em rodízio.
@export var themes: Array[StringName] = [&"basico", &"brasil", &"doces", &"mundo"]
## Loja de troca (DT-062): quantas temporadas de itens exclusivos giram e quantas semanas dura cada uma.
@export var shop_seasons := 2
@export var weeks_per_season := 2


func is_valid() -> bool:
	return first_level >= 1 and arrival_delay >= 0.0 and patience_multiplier > 0.0 and reward_gold >= 0 and reward_xp >= 0 \
		and coupons_at_zero >= 0 and coupons_at_max >= coupons_at_zero and not themes.is_empty() \
		and shop_seasons >= 1 and weeks_per_season >= 1


func gold_at(level: int) -> int:
	return MissionDefinition.round_nice(reward_gold + reward_gold_per_level * (level - 1))


func xp_at(level: int) -> int:
	return MissionDefinition.round_nice(reward_xp + reward_xp_per_level * (level - 1))


func coupons_at(popularity: float) -> int:
	return roundi(lerpf(coupons_at_zero, coupons_at_max, clampf(popularity / 100.0, 0.0, 1.0)))


## A temporada da loja de troca na semana [param week].
func season_for_week(week: int) -> int:
	return posmod(floori(float(week) / weeks_per_season), shop_seasons)


## A aba do tema na semana [param week].
func theme_for_week(week: int) -> StringName:
	return themes[posmod(week, themes.size())]
