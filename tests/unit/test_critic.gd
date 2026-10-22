extends TestCase
## Crítico gastronômico (DT-061): vem uma vez por dia a partir do nível 5, depois de um tempo de café aberto; pede um
## prato da aba da semana; servido rápido, deixa uma estrela que dá ouro, XP e cupons (mais cupons com o café mais
## popular); mal servido, vai embora e volta outro dia. O save guarda a visita e a estrela.

var clock: ManualClock
var sim: CafeSimulation
var config: CriticConfig


func _setup(level_xp := 300) -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.create_new_game(clock, 11)
	sim.config = sim.config.duplicate()  # cópia: o recurso carregado é compartilhado entre os testes
	sim.config.spawn_interval = 1.0e9  # nenhum cliente comum chega: só o crítico
	sim._spawn_timer = 1.0e9
	sim.progression.add_xp(level_xp)  # 300 XP = nível 5
	config = sim.critic_config


## Deixa o café aberto o tempo da chegada do crítico.
func _wait_for_critic() -> Customer:
	sim.tick(config.arrival_delay + 0.1)
	for customer in sim.customers:
		if customer.critic:
			return customer
	return null


## Faz o crítico comer e pagar, servido com [param patience] da paciência sobrando.
func _serve(critic: Customer, patience: float) -> void:
	critic.patience_when_served = patience
	critic.order = sim.recipes.get_definition(&"coffee")
	critic.state = Customer.State.EATING
	critic.eat_left = 0.0
	sim.tick(0.01)


func test_config_is_valid_and_rewards_grow() -> void:
	var critic_config: CriticConfig = load("res://data/config/critic.tres")
	assert_true(critic_config.is_valid())
	assert_true(critic_config.gold_at(20) > critic_config.gold_at(5), "o ouro cresce com o nível")
	assert_true(critic_config.coupons_at(100.0) > critic_config.coupons_at(0.0), "café mais popular, mais cupons")
	assert_eq(critic_config.theme_for_week(0), critic_config.themes[0])
	assert_eq(critic_config.theme_for_week(1), critic_config.themes[1], "cada semana, outro tema")
	assert_eq(critic_config.theme_for_week(critic_config.themes.size()), critic_config.themes[0], "os temas giram")
	var broken: CriticConfig = critic_config.duplicate()
	broken.themes = []
	assert_false(broken.is_valid())


func test_the_critic_comes_once_a_day_from_level_five() -> void:
	_setup(0)
	assert_true(_wait_for_critic() == null, "no nível 1, ainda não vem")
	sim.progression.add_xp(300)
	var arrived: Array = []
	sim.critic_arrived.connect(func(c: Customer) -> void: arrived.append(c))
	sim.tick(config.arrival_delay * 0.5)
	assert_true(arrived.is_empty(), "espera um tempo de café aberto")
	sim.tick(config.arrival_delay * 0.5 + 0.1)
	assert_eq(arrived.size(), 1, "chegou")
	assert_true(arrived[0].critic and arrived[0].is_seated() or arrived[0].state == Customer.State.WALKING_IN)
	var critic: Customer = arrived[0]
	_serve(critic, 1.0)
	sim.critic_star = {}
	sim.tick(config.arrival_delay * 2.0)
	assert_eq(arrived.size(), 1, "uma vez por dia")
	clock.advance(86400.0)
	sim.tick(config.arrival_delay + 0.1)
	assert_eq(arrived.size(), 2, "no outro dia, volta")


func test_a_closed_cafe_gets_no_critic() -> void:
	_setup()
	sim.set_closed(true)
	assert_true(_wait_for_critic() == null)


func test_the_critic_orders_from_the_week_theme() -> void:
	_setup(46000)  # nível 30: todas as receitas
	for week in sim.critic_config.themes.size():  # uma semana em que o tema não é a aba dos pratos mais pedidos
		if sim.critic_theme() != &"basico":
			break
		clock.advance(7 * 86400.0)
	var critic := _wait_for_critic()
	assert_true(critic != null)
	for i in 20:
		critic.state = Customer.State.WAITING_TO_ORDER
		critic.think_left = 0.0
		sim._cancel_order_of(critic)
		critic.order = null
		sim._place_order(critic)
		assert_eq(critic.state, Customer.State.WAITING_FOR_FOOD, "o crítico não pede bebida")
		assert_eq(critic.order.book, sim.critic_theme(), "pede um prato da aba da semana: %s" % critic.order.id)


func test_quick_service_leaves_a_star_with_gold_xp_and_coupons() -> void:
	_setup()
	var critic := _wait_for_critic()
	var left: Array = []
	sim.critic_left.connect(func(_c: Customer, star: bool) -> void: left.append(star))
	_serve(critic, config.quick_service + 0.1)
	assert_eq(left, [true], "servido rápido: deixa a estrela")
	assert_eq(sim.critic_star["cell"], critic.seat_cell, "na mesa onde sentou")
	assert_eq(sim.critic_star["coupons"], config.coupons_at(sim.popularity))
	var gold := sim.wallet.balance(Wallet.SOFT)
	var xp := sim.progression.xp
	var reward := sim.collect_critic_star()
	assert_eq(reward["gold"], config.gold_at(sim.progression.level))
	assert_true(sim.wallet.balance(Wallet.SOFT) >= gold + reward["gold"])
	assert_eq(sim.wallet.balance(Wallet.COUPONS), reward["coupons"], "os cupons entram na carteira")
	assert_true(sim.progression.xp >= xp + reward["xp"] or sim.progression.level > 5)
	assert_true(sim.critic_star.is_empty(), "a estrela some")
	assert_eq(sim.collect_critic_star(), {}, "e não paga duas vezes")


func test_slow_or_no_service_leaves_no_star() -> void:
	_setup()
	var critic := _wait_for_critic()
	var left: Array = []
	sim.critic_left.connect(func(_c: Customer, star: bool) -> void: left.append(star))
	_serve(critic, config.quick_service - 0.1)
	assert_eq(left, [false], "servido devagar: paga, mas sem estrela")
	assert_true(sim.critic_star.is_empty())
	clock.advance(86400.0)
	var second := _wait_for_critic()
	second.patience_left = 0.0
	second.state = Customer.State.WAITING_FOR_FOOD
	sim.tick(0.01)
	assert_eq(left, [false, false], "sem ser servido, vai embora sem estrela")


func test_the_save_keeps_the_visit_and_the_star() -> void:
	_setup()
	var critic := _wait_for_critic()
	_serve(critic, 1.0)
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 11).simulation
	assert_eq(loaded.critic_star, sim.critic_star, "a estrela espera o toque mesmo com o jogo fechado")
	assert_false(loaded.critic_due(), "e ele não volta no mesmo dia")
	var old := SaveCodec.encode(sim)
	old["save_version"] = 14
	old.erase("critic")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(old)))
	assert_eq(migrated["critic"], {}, "a migração acrescenta o crítico")
