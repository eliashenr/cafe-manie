class_name Energy
extends RefCounted
## Energia das máquinas de bebida (DT-052): cada bebida servida gasta alguns pontos, e ela recarrega sozinha,
## 1 ponto a cada tantos segundos, até o máximo do nível. A recarga é pelo relógio do jogo: continua com o
## jogo fechado. Cheia, ela não acumula; a contagem recomeça quando se gasta.

signal changed

var config: EnergyConfig
var _stored := 0
## Instante (relógio do jogo) desde o qual a próxima recarga está contando.
var _since := 0.0
var _max := 0


func _init(energy_config: EnergyConfig, now: float, level := 1) -> void:
	config = energy_config
	_max = config.max_at(level)
	_stored = _max
	_since = now


func maximum() -> int:
	return _max


## Energia agora (já com a recarga do tempo que passou).
func amount(now: float) -> int:
	_settle(now)
	return _stored


func is_full(now: float) -> bool:
	return amount(now) >= _max


## Gasta [param cost] pontos. False (e nada muda) se não houver energia bastante.
func spend(cost: int, now: float) -> bool:
	_settle(now)
	if cost <= 0 or _stored < cost:
		return false
	if _stored >= _max:
		_since = now  # cheia, a recarga não contava: começa agora
	_stored -= cost
	changed.emit()
	return true


## Enche até o máximo (ao subir de nível).
func refill(now: float) -> void:
	_stored = maxi(_stored, _max)
	_since = now
	changed.emit()


## Novo nível: o máximo acompanha.
func set_level(level: int, now: float) -> void:
	_settle(now)
	_max = config.max_at(level)
	changed.emit()


## Segundos até o próximo ponto (0 se está cheia).
func seconds_to_next(now: float) -> float:
	_settle(now)
	if _stored >= _max:
		return 0.0
	return maxf(0.0, _since + config.seconds_per_point - now)


func to_data() -> Dictionary:
	return {"amount": _stored, "since": _since}


## Restaura do save. O relógio [param now] corrige um "desde" no futuro (relógio do aparelho atrasado).
func restore(data: Dictionary, now: float) -> void:
	_stored = maxi(0, int(data.get("amount", _max)))
	_since = minf(float(data.get("since", now)), now)
	_settle(now)
	changed.emit()


func _settle(now: float) -> void:
	if now < _since:
		_since = now  # relógio voltou: a contagem recomeça daqui
	if _stored >= _max:
		_since = now
		return
	var gained := floori((now - _since) / config.seconds_per_point)
	if gained <= 0:
		return
	_stored = mini(_max, _stored + gained)
	_since = now if _stored >= _max else _since + gained * config.seconds_per_point
	changed.emit()
