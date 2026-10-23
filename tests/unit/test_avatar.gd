extends TestCase
## Avatar do chef (DT-070): pele, cabelo, chapéu e roupa; as peças iniciais vêm de graça, as outras se compram uma
## vez (nível e ouro) e depois trocam de graça; o save guarda o que o jogador tem e veste.

const Slot := AvatarPartDefinition.Slot

var clock: ManualClock
var sim: CafeSimulation


func _setup(gold := 1000) -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.with_game_data(clock, CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4)), FurnitureCatalog.load_from(), 5)
	sim.customer_types.clear()
	sim.wallet.earn(Wallet.SOFT, gold, "teste")


func test_the_parts_are_valid_with_one_free_default_per_slot() -> void:
	_setup()
	for part: AvatarPartDefinition in sim.avatar_parts.all():
		assert_true(part.is_valid(), String(part.id))
	for slot: int in Slot.values():
		var parts := sim.avatar_parts_for(slot)
		assert_true(parts.size() >= 4, "opções para escolher: " + Slot.keys()[slot])
		var defaults := parts.filter(func(part: AvatarPartDefinition) -> bool: return part.is_default)
		assert_eq(defaults.size(), 1, "uma peça inicial: " + Slot.keys()[slot])
		assert_eq(defaults[0].price, 0, "a inicial é grátis")
	for part in sim.avatar_parts_for(Slot.SKIN):
		assert_eq(part.price, 0, "todo tom de pele é grátis")
	var broken: AvatarPartDefinition = sim.avatar_parts.get_definition(&"hat_boina").duplicate()
	broken.art = ""
	assert_false(broken.is_valid(), "sem arte")
	broken = sim.avatar_parts.get_definition(&"hat_boina").duplicate()
	broken.price = -1
	assert_false(broken.is_valid(), "preço negativo")


func test_a_new_chef_wears_the_defaults() -> void:
	_setup()
	for slot: int in Slot.values():
		var part := sim.avatar_part(slot)
		assert_true(part != null and part.is_default, Slot.keys()[slot])
		assert_true(sim.avatar.owns(part.id))
	assert_false(sim.avatar.equip(sim.avatar_parts.get_definition(&"hat_coroa")), "só veste peça que é do jogador")
	assert_eq(sim.avatar_part(Slot.HAT).id, &"hat_toque")


func test_buying_a_part_charges_once_and_switching_is_free() -> void:
	_setup()
	sim.progression.add_xp(99999)
	var gold := sim.wallet.balance(Wallet.SOFT)  # subir de nível também dá ouro
	var beret: AvatarPartDefinition = sim.avatar_parts.get_definition(&"hat_boina")
	assert_eq(sim.use_avatar_part(&"hat_boina"), ServiceResult.OK)
	assert_eq(sim.avatar_part(Slot.HAT), beret)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold - beret.price)
	assert_eq(sim.use_avatar_part(&"hat_toque"), ServiceResult.OK, "voltar para o toque")
	assert_eq(sim.avatar_part(Slot.HAT).id, &"hat_toque")
	assert_eq(sim.use_avatar_part(&"hat_boina"), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold - beret.price, "trocar para uma já comprada é grátis")
	assert_eq(sim.avatar_part(Slot.HAIR).id, &"hair_curto_castanho", "chapéu não mexe no cabelo")


func test_a_free_part_is_worn_without_paying() -> void:
	_setup(0)
	assert_eq(sim.use_avatar_part(&"hair_rabo_preto"), ServiceResult.OK)
	assert_eq(sim.avatar_part(Slot.HAIR).id, &"hair_rabo_preto")
	assert_true(sim.avatar.owns(&"hair_rabo_preto"))
	assert_eq(sim.use_avatar_part(&"skin_negra"), ServiceResult.OK)
	assert_eq(sim.avatar_part(Slot.SKIN).id, &"skin_negra")


func test_locked_unaffordable_or_unknown_parts_are_refused_without_charging() -> void:
	_setup(100)
	assert_eq(sim.use_avatar_part(&"hat_coroa"), ServiceResult.AVATAR_LOCKED, "nível 20")
	sim.progression.add_xp(99999)
	sim.wallet.spend(Wallet.SOFT, sim.wallet.balance(Wallet.SOFT) - 100, "teste")  # o ouro dos níveis
	assert_eq(sim.use_avatar_part(&"hat_coroa"), ServiceResult.NOT_ENOUGH_GOLD)
	assert_eq(sim.use_avatar_part(&"hat_nenhum"), ServiceResult.UNKNOWN_ITEM)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 100)
	assert_eq(sim.avatar_part(Slot.HAT).id, &"hat_toque")
	assert_false(sim.avatar.owns(&"hat_coroa"))


func test_the_save_keeps_the_avatar() -> void:
	_setup()
	sim.progression.add_xp(99999)
	sim.use_avatar_part(&"outfit_azul")
	sim.use_avatar_part(&"hair_coque_loiro")
	sim.use_avatar_part(&"outfit_branca")
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 5).simulation
	assert_eq(loaded.avatar_part(Slot.HAIR).id, &"hair_coque_loiro")
	assert_eq(loaded.avatar_part(Slot.OUTFIT).id, &"outfit_branca")
	assert_true(loaded.avatar.owns(&"outfit_azul"), "a roupa comprada continua dele")
	var old := SaveCodec.encode(sim)
	old["save_version"] = 19
	old.erase("avatar")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(old)))
	assert_eq(migrated["avatar"], {}, "a migração acrescenta o avatar")
	var fresh := SaveCodec.decode(migrated, clock, 5).simulation
	assert_eq(fresh.avatar_part(Slot.HAIR).id, &"hair_curto_castanho", "save antigo: as peças iniciais")
	assert_true(fresh.avatar.owns(&"hat_toque"))


func test_a_tampered_save_falls_back_to_the_defaults() -> void:
	_setup()
	var data := SaveCodec.encode(sim)
	data["avatar"] = {"equipped": {str(Slot.HAT): "hat_coroa", str(Slot.HAIR): "hat_boina"}, "owned": ["hat_boina"]}
	var decoded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(JSON.stringify(data))), clock, 5)
	var loaded := decoded.simulation
	assert_eq(loaded.avatar_part(Slot.HAT).id, &"hat_toque", "peça não comprada não fica")
	assert_eq(loaded.avatar.equipped(Slot.HAT), &"hat_toque")
	assert_eq(loaded.avatar_part(Slot.HAIR).id, &"hair_curto_castanho", "peça de outra parte do corpo não fica")
	assert_eq(loaded.avatar.equipped(Slot.HAIR), &"hair_curto_castanho", "e o save corrige o que estava vestido")
	assert_true(loaded.avatar.owns(&"skin_clara"), "as iniciais continuam do jogador")
	assert_false(decoded.warnings.is_empty(), "e o save avisa")


func test_a_broken_equipped_part_shows_the_default() -> void:
	_setup()
	sim.avatar.restore({"equipped": {str(Slot.HAT): "hair_rabo_preto", str(Slot.HAIR): "cabelo_que_sumiu"},
		"owned": ["hair_rabo_preto"]})
	assert_eq(sim.avatar_part(Slot.HAT).id, &"hat_toque", "peça de outra parte do corpo: a inicial")
	assert_eq(sim.avatar_part(Slot.HAIR).id, &"hair_curto_castanho", "peça que não existe: a inicial")
