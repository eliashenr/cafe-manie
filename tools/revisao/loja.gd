extends "res://tools/art_sample.gd"
## Conferência da revisão: abre a loja numa coleção, com a experiência da revisão, fotografa e fecha.

var _count := 0


func _process(delta: float) -> bool:
	_count += 1
	if _count == 45:
		var bar = _cafe.get_node("BuildBar")
		bar.open_shop()
		bar.show_shop_collection(StringName(OS.get_cmdline_user_args()[4]))
	if _count == 60:
		root.get_texture().get_image().save_png(_output)
		print("nivel: ", _cafe.simulation.progression.level, " ouro: ", _cafe.simulation.wallet.balance(&"soft_currency"))
		return true
	return super(delta)
