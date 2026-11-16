extends "res://tools/art_sample.gd"
## Conferência do retrato do chef: abre a janela do avatar, fotografa e fecha. Use a variante "inicial".
## O 5º argumento, se houver, é a aba: 0 pele, 1 cabelo, 2 chapéu, 3 roupa.

var _count := 0


func _process(delta: float) -> bool:
	_count += 1
	if _count == 45:
		var dialog = _cafe.get_node("GameHud").avatar_dialog()
		dialog.show_for(_cafe.simulation)
		var args := OS.get_cmdline_user_args()
		if args.size() > 4:
			dialog.show_slot(int(args[4]))
	if _count == 60:
		root.get_texture().get_image().save_png(_output)
		return true
	return super(delta)
