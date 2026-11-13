extends "res://tools/art_sample.gd"
## Conferência: pisos e paredes no café. Variante "surf:<lote>": 4 pisos em quadrantes e 4 paredes em cada lado.

const FLOOR_GROUPS := [
	["floor_bistro", "floor_blue_tiles", "floor_marble", "floor_70s"],
	["floor_country", "floor_party", "floor_diner", "floor_mexican"],
	["floor_80s", "floor_italian", "floor_japanese", "floor_french"],
	["floor_brazil", "floor_2010s", "floor_club", "floor_oak_light"],
	["floor_70s_carpet", "floor_party_pastel", "floor_diner_red", "floor_country_stone"],
	["floor_cabochon", "floor_italian_cotto", "floor_porcelain", "floor_talavera"],
	["floor_dark_parquet", "floor_80s_grid", "floor_hinoki", "floor_hydraulic"],
	["floor_paris_cabochon", "floor_reclaimed_wood", "floor_black_marble", "floor_mirror"],
	["floor_rose_terrazzo", "floor_gold_mosaic", "floor_chevron", "floor_onyx"],
	["floor_galaxy", "floor_wood", "floor_beige", "floor_marble"],
]
const WALL_GROUPS := [
	["wall_mint_stripes", "wall_navy", "wall_70s", "wall_country"],
	["wall_party", "wall_diner", "wall_mexican", "wall_80s"],
	["wall_italian", "wall_japanese", "wall_french", "wall_brazil"],
	["wall_2010s", "wall_club", "wall_cream", "wall_brick"],
]


func _dress(simulation, variant: String) -> void:
	var batch := int(variant.split(":")[1])
	var style = simulation.style
	var floors: Array = FLOOR_GROUPS[batch % FLOOR_GROUPS.size()]
	var walls: Array = WALL_GROUPS[batch % WALL_GROUPS.size()]
	for q in 4:
		var cells: Array[Vector2i] = []
		for x in 4:
			for y in 4:
				cells.append(Vector2i(x + (q % 2) * 4, y + (q / 2) * 4))
		style.own(StringName(floors[q]))
		style.paint_floor(cells, StringName(floors[q]))
	for i in 8:
		var id := StringName(walls[i / 2])
		style.own(id)
		var segments: Array[String] = [style.segment(style.EDGE_TOP, i), style.segment(style.EDGE_LEFT, i)]
		style.paint_walls(segments, id)


func _populate(_simulation) -> void:
	pass
