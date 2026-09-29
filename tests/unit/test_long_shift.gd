extends TestCase
## Turno longo com o jogo novo de verdade (dados reais, clientes aleatórios)
## e um "jogador robô" que cozinha e serve sempre que pode.
##
## Pega o que testes curtos não pegam: personagem preso, pedido esquecido,
## erro que só aparece depois de muitos ciclos, economia que não fecha.

const STEP := 0.1
const SHIFT_SECONDS := 30.0 * 60.0
## Tempo máximo razoável de um cliente dentro da cafeteria (entrar, esperar, comer, sair).
const MAX_VISIT_SECONDS := 150.0


func test_thirty_minute_shift_runs_clean() -> void:
	var clock := ManualClock.new()
	var sim := CafeSimulation.create_new_game(clock, 2026)
	var arrived_at := {}
	var visits: Array[float] = []
	var happy := [0]
	var angry := [0]
	sim.customer_arrived.connect(func(c: Customer) -> void: arrived_at[c.serial] = clock.now())
	sim.customer_left.connect(func(c: Customer) -> void:
		visits.append(clock.now() - arrived_at[c.serial])
		if c.happy:
			happy[0] += 1
		else:
			angry[0] += 1)

	var stoves: Array[StringName] = []
	for placement in sim.layout.placements():
		if sim.kitchen.is_stove(placement.id):
			stoves.append(placement.id)
	var gold_start := sim.wallet.balance(Wallet.SOFT)

	var elapsed := 0.0
	var next_decision := 0.0
	while elapsed < SHIFT_SECONDS:
		if elapsed >= next_decision:
			_play(sim, stoves)
			next_decision += 1.0
		clock.advance(STEP)
		sim.tick(STEP)
		elapsed += STEP
		for customer in sim.customers:
			if clock.now() - arrived_at[customer.serial] > MAX_VISIT_SECONDS:
				_fail("cliente %d preso no estado %s" % [customer.serial, Customer.State.keys()[customer.state]], "")
				return

	var served: int = happy[0]
	assert_true(served >= 60, "poucos clientes servidos em 30 min: %d" % served)
	assert_true(sim.wallet.balance(Wallet.SOFT) > gold_start, "o turno precisa dar lucro")
	assert_true(sim.progression.level >= 3, "30 min de jogo ativo deveriam render alguns níveis")
	assert_true(float(angry[0]) / maxf(served + angry[0], 1) < 0.25, "muitos clientes irritados: %d de %d" % [angry[0], served + angry[0]])
	for visit in visits:
		assert_true(visit <= MAX_VISIT_SECONDS, "visita longa demais: %.0fs" % visit)
	print("          turno: %d servidos, %d irritados, ouro %d → %d, nível %d, popularidade %d%%" % [
		served, angry[0], gold_start, sim.wallet.balance(Wallet.SOFT), sim.progression.level, roundi(sim.popularity)])


## O robô: serve o que está pronto e cozinha a receita liberada mais lucrativa por minuto que couber no bolso.
func _play(sim: CafeSimulation, stoves: Array[StringName]) -> void:
	for stove in stoves:
		if sim.kitchen.stove_status(stove) == Kitchen.StoveStatus.READY:
			sim.collect(stove)
		if sim.kitchen.stove_status(stove) == Kitchen.StoveStatus.IDLE:
			var best: RecipeDefinition = null
			for recipe in sim.recipes.unlocked_at(sim.progression.level):
				if not sim.wallet.can_afford(Wallet.SOFT, recipe.ingredient_cost) or recipe.cook_time > 120.0:
					continue
				if best == null or recipe.batch_profit() / recipe.cook_time > best.batch_profit() / best.cook_time:
					best = recipe
			if best != null:
				sim.start_cooking(stove, best.id)
