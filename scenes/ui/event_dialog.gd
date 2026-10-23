class_name EventDialog
extends AcceptDialog
## Janela do evento com prazo (DT-063). Na primeira vez de cada edição conta a historinha, um quadro por vez, com o
## retrato de quem conta; depois mostra o prazo, as missões com o progresso e os prêmios (o fogão que sobe de nível
## e o enfeite do fim).

const PORTRAIT_SIZE := Vector2(110, 130)
const TEXT_WIDTH := 460.0

var simulation: CafeSimulation
## Quadro da historinha que está na tela (-1 = mostrando as missões).
var story_page := -1

var _portrait: TextureRect
var _heading: Label
var _text: Label
var _missions: VBoxContainer


func _init() -> void:
	name = "EventDialog"
	title = "Evento"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	add_child(row)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = PORTRAIT_SIZE
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_portrait)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(TEXT_WIDTH, 0)
	row.add_child(column)
	_heading = Label.new()
	_heading.name = "Heading"
	_heading.add_theme_font_size_override("font_size", 20)
	column.add_child(_heading)
	_text = Label.new()
	_text.name = "Text"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(TEXT_WIDTH, 0)
	column.add_child(_text)
	_missions = VBoxContainer.new()
	_missions.name = "Missions"
	column.add_child(_missions)
	confirmed.connect(_on_ok)


## Abre na historinha (se ainda não foi vista nesta edição) ou nas missões.
func show_event() -> void:
	simulation.refresh_event()
	var event := simulation.current_event()
	if event == null:
		return
	title = event.title
	var art := ArtSprites.get_sprite(event.portrait)
	_portrait.texture = art.texture if art != null else null
	story_page = 0 if simulation.event_story_pending() else -1
	_show_page()
	popup_centered()
	get_ok_button().grab_focus()


## Textos das missões, na ordem (para os testes).
func mission_texts() -> Array[String]:
	var texts: Array[String] = []
	for child in _missions.get_children():
		texts.append((child as Label).text)
	return texts


func text() -> String:
	return _text.text


func _on_ok() -> void:
	if story_page < 0:
		return
	story_page += 1
	if story_page >= simulation.current_event().story.size():
		simulation.mark_event_story_seen()
		story_page = -1
	_show_page()
	popup_centered.call_deferred()


func _show_page() -> void:
	var event := simulation.current_event()
	for child in _missions.get_children():
		_missions.remove_child(child)
		child.queue_free()
	if story_page >= 0:
		_heading.text = event.speaker
		_text.text = event.story[story_page]
		ok_button_text = "Próximo" if story_page < event.story.size() - 1 else "Vamos lá!"
		return
	var days := simulation.event_days_left()
	_heading.text = "Termina hoje!" if days == 0 else "Faltam %d dias" % days
	_text.text = _prize_text(event)
	ok_button_text = "Fechar"
	for entry in simulation.event_board.entries():
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(TEXT_WIDTH, 0)
		if entry.done():
			line.text = "✓ %s" % entry.title()
		else:
			line.text = "%s  —  %s/%s  (+%s ouro)" % [entry.title(), UiTheme.thousands(entry.progress),
				UiTheme.thousands(entry.target), UiTheme.thousands(entry.reward_gold)]
		_missions.add_child(line)


func _prize_text(event: EventDefinition) -> String:
	var stove := simulation.furniture.get_definition(event.prize_stove)
	var level := int(simulation.event_stove_levels.get(event.prize_stove, 0))
	var completed := simulation.event_board.completed_count()
	var lines: Array[String] = []
	if stove != null:
		if level >= event.stove_levels_at.size():
			lines.append("%s: nível máximo!" % stove.display_name)
		else:
			var needed := event.stove_levels_at[level] - completed
			lines.append("%s: nível %d de %d. Mais %d %s para o próximo." % [stove.display_name, level,
				event.stove_levels_at.size(), needed, "missão" if needed == 1 else "missões"])
	var final := simulation.furniture.get_definition(event.final_prize)
	if final != null:
		lines.append("Completando tudo: %s." % final.display_name)
	return "\n".join(lines)
