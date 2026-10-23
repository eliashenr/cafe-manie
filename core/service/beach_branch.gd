class_name BeachBranch
extends RefCounted
## A filial na praia (DT-072): aberta ou não, o nível e desde quando junta ouro. O ouro corre com o relógio (também
## com o jogo fechado) até o limite de horas do nível; coletar zera a conta.

signal changed

var config: BranchConfig
var opened := false
## Nível da filial (1 = recém-aberta).
var level := 1
## Horário do relógio da última coleta (ou da abertura).
var since := 0.0


func _init(branch_config: BranchConfig) -> void:
	config = branch_config


func income_per_hour() -> int:
	return config.income_per_hour[clampi(level, 1, config.max_level()) - 1]


func capacity_hours() -> float:
	return config.capacity_hours[clampi(level, 1, config.max_level()) - 1]


## Pratos no cardápio da filial agora: um a mais a cada nível.
func dishes() -> Array[String]:
	var result: Array[String] = []
	result.assign(config.dishes.slice(0, clampi(level, 1, config.max_level())))
	return result


## Ouro guardado esperando a coleta. Com o relógio do aparelho atrasado, a conta recomeça de agora (nada de ficar
## horas sem render esperando o relógio voltar).
func gold_ready(now: float) -> int:
	if not opened:
		return 0
	if since > now:
		since = now
	var hours := clampf((now - since) / 3600.0, 0.0, capacity_hours())
	return floori(hours * income_per_hour())


## Segundos até encher (0 se já está cheia).
func seconds_until_full(now: float) -> float:
	return maxf(since + capacity_hours() * 3600.0 - now, 0.0) if opened else 0.0


func is_max_level() -> bool:
	return level >= config.max_level()


func upgrade_price() -> int:
	return 0 if is_max_level() else config.upgrade_prices[level - 1]


func open(now: float) -> void:
	opened = true
	level = 1
	since = now
	changed.emit()


## Tira o ouro guardado e devolve quanto era.
func collect(now: float) -> int:
	var amount := gold_ready(now)
	since = now
	changed.emit()
	return amount


func level_up() -> void:
	if not is_max_level():
		level += 1
		changed.emit()


func to_data() -> Dictionary:
	return {"open": opened, "level": level, "since": since}


func restore(data: Dictionary) -> void:
	opened = SafeValue.to_bool(data.get("open", false))
	level = clampi(SafeValue.to_int(data.get("level", 1), 1), 1, config.max_level())
	since = SafeValue.to_float(data.get("since", 0.0))
	changed.emit()
