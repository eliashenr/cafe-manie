extends "res://tools/art_sample.gd"
## Conferência das janelas com retratos. Use a variante "inicial" e passe a janela como 5º argumento:
## - "cidade": os vizinhos;
## - "evento": a história do Halloween (com a bruxa);
## - "natal": a história do Natal (com o Papai Noel);
## - "natal_cafe": o café em dezembro, com o Forno do Papai Noel, a Árvore de Natal e o medalhão do evento, sem janela aberta.

## Um dia dentro de cada evento, para a janela dele ter o que mostrar.
const EVENT_DAYS := {"evento": "2026-10-25T14:00:00", "natal": "2026-12-10T14:00:00", "natal_cafe": "2026-12-10T14:00:00"}

var _count := 0


func _process(delta: float) -> bool:
	_count += 1
	var which: String = OS.get_cmdline_user_args()[4]
	if _count == 30 and which == "natal_cafe":
		var catalog = load("res://core/furniture/furniture_catalog.gd").load_from()
		var layout = _cafe.simulation.layout
		for spot in [[&"santa_oven", Vector2i(2, 0)], [&"christmas_tree", Vector2i(0, 5)], [&"christmas_tree", Vector2i(6, 6)]]:
			if layout.place(catalog.get_definition(spot[0]), spot[1], 0) == &"":
				printerr("Não coube: ", spot[0], " em ", spot[1])
	if _count == 40:
		var hud = _cafe.get_node("GameHud")
		if which == "cidade":
			hud.show_city()
			hud.city_dialog().show_tab(&"neighbors")
		else:
			_clock.time = Time.get_unix_time_from_datetime_string(EVENT_DAYS[which]) - _clock.utc_offset_seconds()
			_cafe.simulation.refresh_event()
			if which != "natal_cafe":
				hud.show_event()
	if _count == 60:
		root.get_texture().get_image().save_png(_output)
		return true
	return super(delta)
