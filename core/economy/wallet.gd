class_name Wallet
extends RefCounted
## Saldos das moedas do jogador.
##
## Toda alteração de saldo passa por earn() ou spend(), que registram o
## motivo. Hoje roda local; na Fase 6 o servidor passa a validar as mesmas
## operações (seção 62). Moedas são identificadas por ids neutros; o nome
## exibido ("Café Ouro"...) é assunto da interface.

signal balance_changed(currency: StringName, balance: int)

const SOFT := &"soft_currency"
const PREMIUM := &"premium_currency"
## Quantas transações recentes o registro guarda.
const LOG_LIMIT := 200

var _balances: Dictionary = {}  # StringName -> int
var _log: Array[Dictionary] = []


func balance(currency: StringName) -> int:
	return _balances.get(currency, 0)


func can_afford(currency: StringName, amount: int) -> bool:
	return amount >= 0 and balance(currency) >= amount


## Soma ao saldo. Recusa valores que não sejam positivos.
func earn(currency: StringName, amount: int, reason: String) -> bool:
	if amount <= 0:
		return false
	_apply(currency, amount, reason)
	return true


## Desconta do saldo. Recusa, sem alterar nada, se faltar saldo ou o valor não for positivo.
func spend(currency: StringName, amount: int, reason: String) -> bool:
	if amount <= 0 or not can_afford(currency, amount):
		return false
	_apply(currency, -amount, reason)
	return true


## Transações recentes, da mais antiga para a mais nova:
## [code]{currency, delta, balance, reason}[/code].
func history() -> Array[Dictionary]:
	return _log.duplicate()


func _apply(currency: StringName, delta: int, reason: String) -> void:
	var new_balance := balance(currency) + delta
	_balances[currency] = new_balance
	_log.append({"currency": currency, "delta": delta, "balance": new_balance, "reason": reason})
	if _log.size() > LOG_LIMIT:
		_log.pop_front()
	balance_changed.emit(currency, new_balance)
