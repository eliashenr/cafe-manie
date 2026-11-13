extends "res://tools/art_sample.gd"
## Conferência: itens de parede e portas no café. Variante "parede:<lote>:<porta>" (porta: frances, japones... ou classico).

const ITEMS := ["janela_redonda", "janela_diner", "janela_neon", "janela_groovy", "janela_arcade", "janela_shoji", "janela_country",
	"janela_festa", "janela_industrial", "janelao", "janelao_italiano", "janelao_mexicano", "janelao_brasileiro", "janelao_frances",
	"espelho", "lousa", "neon_xicara", "painel_digital", "planta_pendurada", "radio", "tv", "janela", "quadro_cupcake",
	"quadro_paisagem", "prateleira", "relogio", "arandela"]
const PER_BATCH := 16


func _dress(simulation, variant: String) -> void:
	var parts := variant.split(":")
	var batch := int(parts[1])
	var style = simulation.style
	for i in PER_BATCH:
		var index := batch * PER_BATCH + i
		if index >= ITEMS.size():
			break
		var id := StringName(ITEMS[index])
		var segments: Array[String] = [style.segment(style.EDGE_TOP if i < 8 else style.EDGE_LEFT, i % 8)]
		style.own(id)
		style.hang(segments, id)
	if parts.size() > 2:
		var door := StringName("door_" + parts[2])
		style.own(door)
		style.set_door(door)


func _populate(_simulation) -> void:
	pass
