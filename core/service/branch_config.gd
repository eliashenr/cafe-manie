class_name BranchConfig
extends Resource
## Filial na praia (DT-072, res://data/config/branch.tres): um segundo café, na praia, que funciona sozinho. Aberta,
## ela rende ouro por hora (também com o jogo fechado), guardado até um limite de horas; cada melhoria põe mais um
## prato da praia no cardápio dela e aumenta o rendimento.

@export var display_name := "Filial na Praia"
@export var unlock_level := 15
@export var open_price := 8000

@export_group("Por nível da filial")
## Índice 0 = nível 1. Ouro por hora, horas de ouro que ela guarda e o prato que entra no cardápio no nível.
@export var income_per_hour: Array[int] = [240, 420, 660, 960]
@export var capacity_hours: Array[float] = [6.0, 8.0, 10.0, 12.0]
@export var dishes: Array[String] = ["Açaí na tigela", "Peixe frito", "Picolé de frutas", "Água de coco"]
## Preço para subir de nível (índice 0 = do nível 1 para o 2).
@export var upgrade_prices: Array[int] = [12000, 25000, 45000]

@export_group("Balanceamento")
## XP a cada 100 de ouro coletado.
@export var xp_per_100_gold := 5


func max_level() -> int:
	return income_per_hour.size()


func is_valid() -> bool:
	var levels := max_level()
	if levels < 1 or capacity_hours.size() != levels or dishes.size() != levels or upgrade_prices.size() != levels - 1:
		return false
	for i in levels:
		if income_per_hour[i] <= 0 or capacity_hours[i] <= 0.0 or (i > 0 and income_per_hour[i] <= income_per_hour[i - 1]):
			return false
	return unlock_level >= 1 and open_price >= 0 and xp_per_100_gold >= 0 and upgrade_prices.all(func(p: int) -> bool: return p >= 0)
