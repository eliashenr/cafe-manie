class_name RecipeMastery
extends RefCounted
## Domínio das receitas (DT-053): conta quantas vezes cada receita saiu pronta do fogão e dá uma estrela (com
## prêmio) a cada meta da MasteryConfig. As estrelas aparecem no livro de receitas.

signal changed

var config: MasteryConfig
var _counts := {}  # StringName -> int


func _init(mastery_config: MasteryConfig) -> void:
	config = mastery_config


## Mais um prato pronto da receita. Retorna quantas estrelas ela ganhou agora (0 na maioria das vezes).
func record(recipe_id: StringName) -> int:
	var before := stars(recipe_id)
	_counts[recipe_id] = count(recipe_id) + 1
	changed.emit()
	return stars(recipe_id) - before


func count(recipe_id: StringName) -> int:
	return int(_counts.get(recipe_id, 0))


func stars(recipe_id: StringName) -> int:
	var total := 0
	for threshold in config.thresholds:
		if count(recipe_id) >= threshold:
			total += 1
	return total


## Pratos que faltam para a próxima estrela: a meta (-1 se já tem todas).
func next_goal(recipe_id: StringName) -> int:
	var earned := stars(recipe_id)
	return config.thresholds[earned] if earned < config.max_stars() else -1


## Prêmio da estrela [param star] (1 = a primeira) da receita: {"gold": int, "xp": int}.
func reward(recipe: RecipeDefinition, star: int) -> Dictionary:
	var index := clampi(star - 1, 0, config.max_stars() - 1)
	return {"gold": roundi(recipe.ingredient_cost * config.gold_multipliers[index]),
		"xp": roundi(recipe.xp_reward * config.xp_multipliers[index])}


func to_data() -> Dictionary:
	var data := {}
	for id: StringName in _counts:
		data[String(id)] = _counts[id]
	return data


func restore(data: Dictionary) -> void:
	_counts.clear()
	for key in data:
		var value := int(data[key])
		if value > 0:
			_counts[StringName(str(key))] = value
	changed.emit()
