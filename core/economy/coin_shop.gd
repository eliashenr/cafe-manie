class_name CoinShop
extends RefCounted
## Loja de Café Ouro por dinheiro de verdade: os pacotes (em dados) e a compra por um PaymentProvider.
##
## O jogo nunca entrega ouro sem a confirmação do provedor de pagamento. Neste build (Windows e APK de
## teste) o provedor é o UnavailablePaymentProvider: a compra fica indisponível até o jogo estar na Play
## Store com a cobrança da Google configurada pelo dono da conta (ver DT-044).

signal purchase_finished(pack: CoinPack, result: int)

enum Result { OK, UNAVAILABLE, CANCELLED, FAILED, UNKNOWN_PACK }

const DEFAULT_DIR := "res://data/coin_packs"

var provider: PaymentProvider
var _store: DefinitionStore
var _wallet: Wallet


func _init(wallet: Wallet, payment_provider: PaymentProvider = null) -> void:
	_wallet = wallet
	provider = payment_provider if payment_provider != null else UnavailablePaymentProvider.new()
	_store = DefinitionStore.new(func(a: CoinPack, b: CoinPack) -> bool: return a.order < b.order)


static func load_from(wallet: Wallet, payment_provider: PaymentProvider = null, dir_path := DEFAULT_DIR) -> CoinShop:
	var shop := CoinShop.new(wallet, payment_provider)
	shop._store.load_dir(dir_path, CoinPack)
	return shop


func add(pack: CoinPack) -> bool:
	return _store.add(pack)


func packs() -> Array[CoinPack]:
	var result: Array[CoinPack] = []
	result.assign(_store.all())
	return result


func get_pack(id: StringName) -> CoinPack:
	return _store.get_definition(id) as CoinPack


## A compra pode acontecer neste aparelho?
func is_available() -> bool:
	return provider.is_available()


## Pede a compra ao provedor; o ouro só entra quando ele confirma o pagamento.
func buy(pack_id: StringName) -> int:
	var pack := get_pack(pack_id)
	if pack == null:
		return Result.UNKNOWN_PACK
	var result := provider.purchase(pack.product_id)
	if result == Result.OK:
		_wallet.earn(Wallet.SOFT, pack.gold, "Compra: %s" % pack.display_name)
	purchase_finished.emit(pack, result)
	return result
