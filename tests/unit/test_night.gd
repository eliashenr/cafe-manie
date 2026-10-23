extends TestCase
## Noite no café (DT-064): das 19h às 6h é noite (escurecendo e clareando aos poucos); o cardápio noturno só começa à
## noite, no Fogão Lua Cheia, e os clientes só pedem esses pratos à noite.

const NIGHT_DISHES: Array[StringName] = [&"petit_gateau", &"caldo_verde", &"mushroom_risotto", &"fondue"]

var clock: ManualClock
var sim: CafeSimulation
var config: NightConfig


func _setup(hour: float) -> void:
	clock = ManualClock.new()
	clock.offset = 0
	clock.time = Time.get_unix_time_from_datetime_string("2026-10-25T00:00:00") + hour * 3600.0
	var no_customers: Array[CustomerType] = []
	sim = CafeSimulation.new(clock, CafeLayout.new(Vector2i(10, 10), Vector2i(9, 5)), load("res://data/config/service.tres"),
		FurnitureCatalog.load_from(), RecipeCatalog.load_from(), load("res://data/progression/levels.tres"), no_customers, 7)
	sim.wallet.earn(Wallet.SOFT, 100000, "teste")
	sim.progression.add_xp(46000)  # nível 30
	sim.layout.place(sim.furniture.get_definition(&"counter_basic"), Vector2i(8, 8))
	config = sim.night_config


func test_config_and_the_night_hours() -> void:
	var night_config: NightConfig = load("res://data/config/night.tres")
	assert_true(night_config.is_valid())
	assert_false(night_config.is_night(18.9), "18h50 ainda é dia")
	assert_true(night_config.is_night(19.0))
	assert_true(night_config.is_night(2.0), "madrugada é noite")
	assert_false(night_config.is_night(6.0), "às 6h amanhece")
	assert_eq(night_config.darkness(12.0), 0.0, "meio-dia, sem escuro")
	assert_almost_eq(night_config.darkness(19.5), 0.5, 0.001, "no meio do anoitecer, meio escuro")
	assert_eq(night_config.darkness(23.0), 1.0, "noite fechada")
	assert_almost_eq(night_config.darkness(5.5), 0.5, 0.001, "amanhecendo")
	var broken: NightConfig = night_config.duplicate()
	broken.twilight_hours = 0.0
	assert_false(broken.is_valid())


func test_the_night_menu_data() -> void:
	var catalog := RecipeCatalog.load_from()
	assert_eq(catalog.in_book(&"noite").size(), NIGHT_DISHES.size())
	for id in NIGHT_DISHES:
		var recipe := catalog.get_definition(id)
		assert_true(recipe.night_only, "%s é do cardápio noturno" % id)
		assert_eq(recipe.stove, &"stove_moon", "%s sai no Fogão Lua Cheia" % id)
	var moon := FurnitureCatalog.load_from().get_definition(&"stove_moon")
	assert_true(moon.stove_servings_bonus > 0.0, "o fogão da noite rende mais")
	assert_true(moon.light_radius > 0.0, "e brilha à noite")
	assert_true(FurnitureCatalog.load_from().get_definition(&"floor_lamp").light_radius > 0.0, "as luminárias acendem")


func test_night_dishes_only_start_at_night() -> void:
	_setup(12.0)
	var moon := sim.layout.place(sim.furniture.get_definition(&"stove_moon"), Vector2i(2, 2))
	assert_false(sim.is_night())
	assert_eq(sim.start_cooking(moon, &"fondue"), ServiceResult.NOT_NIGHT, "de dia, não começa")
	assert_eq(sim.start_cooking(moon, &"coffee"), ServiceResult.OK, "os pratos comuns saem nele de dia")
	_setup(21.0)
	moon = sim.layout.place(sim.furniture.get_definition(&"stove_moon"), Vector2i(2, 2))
	assert_true(sim.is_night())
	assert_eq(sim.start_cooking(moon, &"fondue"), ServiceResult.OK, "à noite, sai")
	var fondue := sim.recipes.get_definition(&"fondue")
	assert_true(sim.kitchen.stove_servings(moon) > fondue.servings, "com as porções a mais do fogão")
	_setup(5.5)  # 5h30: ainda é noite
	moon = sim.layout.place(sim.furniture.get_definition(&"stove_moon"), Vector2i(2, 2))
	assert_eq(sim.start_cooking(moon, &"fondue"), ServiceResult.OK)
	clock.advance(fondue.cook_time)  # 6h30: amanheceu com o prato no fogão
	assert_false(sim.is_night())
	assert_eq(sim.kitchen.stove_status(moon), Kitchen.StoveStatus.READY, "o que começou à noite termina de dia")


func test_customers_order_night_dishes_only_at_night() -> void:
	_setup(12.0)
	sim.layout.place(sim.furniture.get_definition(&"stove_moon"), Vector2i(2, 2))
	for recipe in sim.order_menu():
		assert_false(recipe.night_only, "%s não aparece de dia" % recipe.id)
	clock.advance(9 * 3600.0)  # 21h
	var ids: Array[StringName] = []
	for recipe in sim.order_menu():
		ids.append(recipe.id)
	for id in NIGHT_DISHES:
		assert_true(ids.has(id), "%s entra no cardápio à noite" % id)


func test_night_falling_is_announced_once() -> void:
	_setup(18.5)
	var changes: Array = []
	sim.night_changed.connect(func(night: bool) -> void: changes.append(night))
	sim.tick(0.1)
	assert_true(changes.is_empty(), "ainda é dia")
	clock.advance(3600.0)
	sim.tick(0.1)
	sim.tick(0.1)
	assert_eq(changes, [true], "anoiteceu, uma vez")
	clock.advance(11 * 3600.0)
	sim.tick(0.1)
	assert_eq(changes, [true, false], "amanheceu")
