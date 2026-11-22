extends RefCounted
## Fixture para continuar verificando animação procedural, mesmo após trocar a arte de produção.
## Substitui só o cache de sprites em pé de um cliente; restore() devolve os objetos originais.

var _originals: Dictionary = {}


func use_customer(serial := 0) -> void:
	var looks: Array = ArtSprites.characters().get("customers", [])
	if looks.is_empty():
		return
	var look: String = looks[posmod(serial, looks.size())]
	for direction in ["frente", "costas"]:
		for index in range(-1, AgentView.WALK_FRAMES):
			var pose := "em_pe" if index < 0 else "passo_%d" % index
			var name := "%s_%s_%s" % [look, direction, pose]
			if _originals.has(name):
				continue
			var original := ArtSprites.get_sprite(name)
			if original == null:
				continue
			_originals[name] = original
			var legacy := ArtSprites.Sprite.new()
			legacy.texture = original.texture
			legacy.anchor = original.anchor
			legacy.density = original.density
			legacy.tray = original.tray.duplicate()
			# Os defaults false simulam um manifesto anterior às opções de movimento e sombra.
			ArtSprites._cache[name] = legacy


func restore() -> void:
	for name: String in _originals:
		ArtSprites._cache[name] = _originals[name]
	_originals.clear()
