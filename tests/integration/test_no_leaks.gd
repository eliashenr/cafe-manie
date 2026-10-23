extends CafeTestCase
## QA (23/10): abrir e fechar as janelas e a loja muitas vezes não deixa objetos perdidos para trás (vazamento de
## memória que, no celular, deixaria o jogo cada vez mais pesado).

const ROUNDS := 25
## Folga para o que o Godot ainda vai liberar no próximo quadro.
const SLACK := 20


func test_opening_and_closing_windows_does_not_leak() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.progression.add_xp(99999)
	cafe.simulation.wallet.earn(Wallet.SOFT, 99999, "teste")
	await _cycle(cafe)  # a primeira volta cria o que fica guardado (texturas, fontes)
	await settle()
	var before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var nodes_before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	for i in ROUNDS:
		await _cycle(cafe)
	await settle()
	await settle()
	var after := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var nodes_after := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	assert_true(after - before <= SLACK, "nós perdidos: %d → %d" % [before, after])
	assert_true(nodes_after - nodes_before <= SLACK, "nós na cena: %d → %d" % [nodes_before, nodes_after])


func _cycle(cafe: Cafe) -> void:
	cafe.hud.show_avatar()
	await settle()
	var avatar := cafe.hud.avatar_dialog()
	for slot: int in AvatarPartDefinition.Slot.values():
		avatar.show_slot(slot)
	avatar.hide()
	cafe.hud.show_city()
	await settle()
	var city := cafe.hud.city_dialog()
	city.show_tab(&"neighbors")
	city.show_tab(&"branch")
	city.hide()
	for tab in [BuildBar.ShopTab.SALON, BuildBar.ShopTab.WALL, BuildBar.ShopTab.FLOOR]:
		cafe.build_bar.open_shop(tab)
		await settle()
	cafe.build_bar.close_shop()
	await settle()
