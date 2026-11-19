extends "res://tools/art_sample.gd"
## Conferência das janelas com retratos: "cidade" abre os vizinhos; "evento" abre a história do evento (com a bruxa).
## Use a variante "inicial" e passe a janela como 5º argumento.

## Um dia dentro do evento de Halloween (de 20/10 a 3/11), para a janela dele ter o que mostrar.
const EVENT_DAY := "2026-10-25T14:00:00"

var _count := 0


func _process(delta: float) -> bool:
	_count += 1
	if _count == 40:
		var hud = _cafe.get_node("GameHud")
		var which: String = OS.get_cmdline_user_args()[4]
		if which == "cidade":
			hud.show_city()
			hud.city_dialog().show_tab(&"neighbors")
		else:
			_clock.time = Time.get_unix_time_from_datetime_string(EVENT_DAY) - _clock.utc_offset_seconds()
			_cafe.simulation.refresh_event()
			hud.show_event()
	if _count == 60:
		root.get_texture().get_image().save_png(_output)
		return true
	return super(delta)
