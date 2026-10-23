extends TestCase
## Portas da entrada e coleções completas (DT-067): cada coleção tem a sua porta, que se compra uma vez e
## depois troca de graça; cada coleção também tem fogão, balcão e janela próprios.

var clock: ManualClock
var sim: CafeSimulation


func _setup(gold := 1000) -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.with_game_data(clock, CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4)), FurnitureCatalog.load_from(), 5)
	sim.customer_types.clear()
	sim.wallet.earn(Wallet.SOFT, gold, "teste")


func test_every_collection_has_a_valid_door_and_one_is_the_free_default() -> void:
	_setup()
	var defaults := sim.doors.all().filter(func(door: DoorDefinition) -> bool: return door.is_default)
	assert_eq(defaults.size(), 1, "uma porta inicial")
	assert_eq(defaults[0].price, 0, "a inicial é grátis")
	for door: DoorDefinition in sim.doors.all():
		assert_true(door.is_valid(), String(door.id))
	for collection in sim.collections.all():
		var found := sim.doors.all().filter(func(door: DoorDefinition) -> bool: return door.collection == collection.id)
		assert_eq(found.size(), 1, "uma porta para " + String(collection.id))
	var broken: DoorDefinition = sim.doors.get_definition(&"door_frances").duplicate()
	broken.price = -1
	assert_false(broken.is_valid(), "preço negativo")
	var nameless: DoorDefinition = sim.doors.get_definition(&"door_frances").duplicate()
	nameless.id = &""
	assert_false(nameless.is_valid(), "sem id")


func test_every_collection_is_complete() -> void:
	var catalog := FurnitureCatalog.load_from()
	var walls: Array = []
	for path in DirAccess.get_files_at("res://data/wall_items"):
		if path.ends_with(".tres"):
			walls.append(load("res://data/wall_items/" + path))
	_setup()
	for collection in sim.collections.all():
		var id: StringName = collection.id
		var has := func(category: FurnitureDefinition.Category) -> bool:
			return catalog.all().any(func(d: FurnitureDefinition) -> bool:
				return d.collection == id and d.category == category and d.sold_for_gold)
		assert_true(has.call(FurnitureDefinition.Category.COOKING), "fogão da coleção " + String(id))
		assert_true(has.call(FurnitureDefinition.Category.COUNTER), "balcão da coleção " + String(id))
		assert_true(walls.any(func(w: WallItemDefinition) -> bool: return w.collection == id and w.lets_light_in),
			"janela da coleção " + String(id))


func test_a_new_cafe_starts_with_the_classic_door() -> void:
	_setup()
	assert_eq(sim.current_door().id, &"door_classico")
	assert_eq(sim.style.door_id, &"door_classico")
	assert_true(sim.style.owns(&"door_classico"))
	assert_false(sim.style.set_door(&"door_frances"), "o estilo só aceita porta comprada")
	assert_eq(sim.style.door_id, &"door_classico")
	sim.style.door_id = &"porta_que_sumiu"
	assert_eq(sim.current_door().id, &"door_classico", "porta que não existe mais: a clássica")


func test_buying_a_door_charges_once_and_switching_is_free() -> void:
	_setup(1000)
	sim.progression.add_xp(99999)
	var gold := sim.wallet.balance(Wallet.SOFT)  # subir de nível também dá ouro
	var door: DoorDefinition = sim.doors.get_definition(&"door_anos70")
	assert_eq(sim.use_door(&"door_anos70"), ServiceResult.OK)
	assert_eq(sim.current_door(), door)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold - door.price)
	assert_eq(sim.use_door(&"door_classico"), ServiceResult.OK, "voltar para a clássica")
	assert_eq(sim.current_door().id, &"door_classico")
	assert_eq(sim.use_door(&"door_anos70"), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold - door.price, "trocar para uma já comprada é grátis")


func test_locked_unaffordable_or_unknown_door_is_refused_without_charging() -> void:
	_setup(100)
	assert_eq(sim.use_door(&"door_frances"), ServiceResult.DOOR_LOCKED, "nível 7")
	sim.progression.add_xp(99999)
	sim.wallet.spend(Wallet.SOFT, sim.wallet.balance(Wallet.SOFT) - 100, "teste")  # o ouro dos níveis
	assert_eq(sim.use_door(&"door_frances"), ServiceResult.NOT_ENOUGH_GOLD)
	assert_eq(sim.use_door(&"door_nenhuma"), ServiceResult.UNKNOWN_ITEM)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 100)
	assert_eq(sim.current_door().id, &"door_classico")
	assert_false(sim.style.owns(&"door_frances"))


func test_the_door_adds_beauty() -> void:
	_setup(1000)
	sim.progression.add_xp(99999)
	var before := sim.beauty()
	sim.use_door(&"door_anos70")
	assert_eq(sim.beauty(), before + sim.doors.get_definition(&"door_anos70").beauty)


func test_the_save_keeps_the_door() -> void:
	_setup(1000)
	sim.progression.add_xp(99999)
	sim.use_door(&"door_festa")
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 5).simulation
	assert_eq(loaded.current_door().id, &"door_festa")
	assert_true(loaded.style.owns(&"door_festa"))
	var old := SaveCodec.encode(sim)
	old["style"].erase("door")
	var restored := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(JSON.stringify(old))), clock, 5).simulation
	assert_eq(restored.current_door().id, &"door_classico", "save sem porta: a clássica")
	old["style"]["door"] = "door_frances"
	var tampered := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(JSON.stringify(old))), clock, 5)
	assert_eq(tampered.simulation.current_door().id, &"door_classico", "porta que não foi comprada não fica")
	assert_eq(tampered.simulation.style.door_id, &"door_classico")
