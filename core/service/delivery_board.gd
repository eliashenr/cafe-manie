class_name DeliveryBoard
extends RefCounted
## Pedidos de entrega (DT-071): até max_orders esperando; enquanto houver lugar, chega um novo a cada intervalo do
## relógio (também com o jogo fechado). Com o quadro cheio, o próximo chega um intervalo depois da entrega.

signal changed


class Order:
	extends RefCounted
	var recipe: RecipeDefinition
	var servings := 0
	var gold := 0
	var xp := 0


var config: DeliveryConfig
var orders: Array[Order] = []
## Horário do relógio em que chega o próximo pedido (0 = assim que houver Balcão de Entregas).
var next_at := 0.0
## Muda a cada pedido que chega ou sai (para a interface saber que precisa se refazer).
var version := 0


func _init(delivery_config: DeliveryConfig) -> void:
	config = delivery_config


## Traz os pedidos que chegaram até [param now], sorteados entre as receitas do cardápio.
func refresh(now: float, menu: Array[RecipeDefinition], rng: RandomNumberGenerator) -> void:
	if menu.is_empty():
		return
	if next_at <= 0.0:
		next_at = now
	var arrived := false
	while orders.size() < config.max_orders and now >= next_at:
		orders.append(make_order(menu[rng.randi_range(0, menu.size() - 1)], rng.randi_range(config.min_servings, config.max_servings)))
		next_at += config.order_interval
		arrived = true
	if arrived:
		_changed()


func make_order(recipe: RecipeDefinition, servings: int) -> Order:
	var order := Order.new()
	order.recipe = recipe
	order.servings = servings
	order.gold = roundi(servings * recipe.sell_price * config.gold_multiplier)
	order.xp = servings * config.xp_per_serving
	return order


## Tira o pedido entregue. Com o quadro cheio, o próximo chega um intervalo depois de agora.
func complete(index: int, now: float) -> void:
	if orders.size() >= config.max_orders:
		next_at = maxf(next_at, now + config.order_interval)
	orders.remove_at(index)
	_changed()


## Segundos até o próximo pedido (0 se já devia ter chegado).
func seconds_until_next(now: float) -> float:
	return maxf(next_at - now, 0.0)


func to_data() -> Dictionary:
	var list: Array = []
	for order in orders:
		list.append({"recipe": String(order.recipe.id), "servings": order.servings, "gold": order.gold, "xp": order.xp})
	return {"orders": list, "next_at": next_at}


func restore(data: Dictionary, recipes: RecipeCatalog) -> void:
	orders.clear()
	for entry in data.get("orders", []):
		if not entry is Dictionary:
			continue
		var recipe := recipes.get_definition(StringName(str(entry.get("recipe", ""))))
		if recipe == null:
			continue
		var order := Order.new()
		order.recipe = recipe
		order.servings = maxi(1, int(entry.get("servings", 1)))
		order.gold = maxi(0, int(entry.get("gold", 0)))
		order.xp = maxi(0, int(entry.get("xp", 0)))
		orders.append(order)
	next_at = float(data.get("next_at", 0.0))
	_changed()


func _changed() -> void:
	version += 1
	changed.emit()
