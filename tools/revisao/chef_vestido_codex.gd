extends "res://tools/art_sample.gd"
## Prova estática de encaixe: uma única imagem completa, sem camadas, animação ou compra.
## Não lê nem grava save: art_sample injeta a simulação e desativa a gravação do som.
## Uso: godot --resolution 1280x720 -s res://tools/revisao/chef_vestido_codex.gd --
##      <saida.png> mostruario dia foto [tamanho|detalhe|suite]
## Em revisao, o café segue vivo; C reabre a prova, D alterna o tamanho e N muda dia/noite.
## suite grava <saida.png> em 210x255 e <saida>_detalhe.png em 336x408.

const CHEF_PATH := "res://art/avatar/chef_vestido_v1.png"
const PORTRAIT_SIZE := Vector2(210, 255)
const DETAIL_SIZE := Vector2(336, 408)
const CAPTURE_FRAME := 45

var _proof_frames := 0
var _proof_request := "tamanho"
var _proof_detail := false
var _proof_failed := false
var _proof_capturing := false
var _proof_texture: Texture2D
var _proof_dialog: AcceptDialog
var _proof_portrait: TextureRect
var _proof_caption: Label
var _proof_toggle: Button
var _proof_dim: ColorRect


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 4:
		_proof_request = args[4]
	if _proof_request not in ["tamanho", "detalhe", "suite"]:
		_fail("Vista desconhecida: " + _proof_request)
		return
	if not FileAccess.file_exists(CHEF_PATH):
		_fail("A imagem do chef ainda não está disponível: " + CHEF_PATH)
		return
	# Usa a textura importada, pelo mesmo caminho de recursos do jogo.
	_proof_texture = load(CHEF_PATH) as Texture2D
	if _proof_texture == null:
		_fail("Não foi possível carregar a textura importada do chef: " + CHEF_PATH)
		return
	_proof_detail = _proof_request == "detalhe"
	super()
	root.title = "Chef vestido · prova parada · C: chef · D: detalhe · N: dia/noite · sem salvar"
	root.window_input.connect(_on_proof_input)

func _dress(simulation, variant: String) -> void:
	super(simulation, variant)
	# Só nesta amostra: não oferece presente ao restaurar a janela minimizada.
	# Desativa o calendário da instância, sem receber prêmio nem mudar posse/saldo.
	simulation.daily.calendar = null


func _process(delta: float) -> bool:
	if _proof_failed:
		return true
	if _cafe == null or not _cafe.is_inside_tree():
		_fail("O café não montou a prova estática.")
		return true
	_proof_frames += 1
	if _proof_frames <= REVIEW_HIDE_FRAMES:
		for window: Window in _cafe.find_children("*", "Window", true, false):
			window.hide()
	if _proof_frames == REVIEW_HIDE_FRAMES + 1:
		_cafe.camera.zoom = Vector2.ONE * 0.9
		_cafe.camera.global_position = IsoProjection.grid_bounds(Vector2i(8, 8)).get_center() - Vector2(0, 52)
		_cafe.camera.force_update_scroll()
		_create_proof()
		_show_proof()
		if not _review:
			_cafe.set_paused(true)
			_cafe.hud.show_pause_state(false)
	if _review:
		_clock.time += delta
	elif _proof_frames >= CAPTURE_FRAME and not _proof_capturing:
		_proof_capturing = true
		_capture_proof.call_deferred()
	return false


func _create_proof() -> void:
	_cafe.hud.find_child("DailyButton", true, false).hide()
	var layer := CanvasLayer.new()
	layer.name = "ChefProofLayer"
	layer.layer = 3
	root.add_child(layer)
	_proof_dim = ColorRect.new()
	_proof_dim.name = "ChefProofDim"
	_proof_dim.color = Color(0.16, 0.11, 0.08, 0.50)
	_proof_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_proof_dim.visible = false
	layer.add_child(_proof_dim)
	_proof_dialog = AcceptDialog.new()
	_proof_dialog.name = "ChefDressedProof"
	_proof_dialog.title = "Chef — revisão de encaixe"
	_proof_dialog.ok_button_text = "Fechar"
	_proof_dialog.theme = UiTheme.theme()
	_proof_dialog.exclusive = true
	UiTheme.style_dialog(_proof_dialog, UiTheme.GHOST_BUTTON)
	layer.add_child(_proof_dialog)
	_proof_dialog.visibility_changed.connect(func() -> void: _proof_dim.visible = _proof_dialog.visible)
	_proof_dialog.window_input.connect(_on_proof_input)
	_proof_dialog.window_input.connect(_on_review_input)
	_proof_toggle = _proof_dialog.add_button("Ver ampliado", true, "detail")
	UiTheme.role(_proof_toggle, UiTheme.SUCCESS_BUTTON)
	_proof_dialog.custom_action.connect(func(action: StringName) -> void:
		if action == &"detail":
			_set_detail(not _proof_detail))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	_proof_dialog.add_child(row)
	var stage := PanelContainer.new()
	stage.name = "Stage"
	stage.add_theme_stylebox_override("panel", UiTheme.glass_box(18, 12, UiTheme.PANEL_EDGE))
	row.add_child(stage)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	stage.add_child(column)
	_proof_portrait = TextureRect.new()
	_proof_portrait.name = "ChefStaticPortrait"
	_proof_portrait.texture = _proof_texture
	_proof_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_proof_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_proof_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_proof_portrait)
	_proof_caption = UiTheme.caption("", UiTheme.TEXT_SOFT, 13)
	_proof_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_proof_caption)
	var explanation := VBoxContainer.new()
	explanation.custom_minimum_size.x = 260
	explanation.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	explanation.add_theme_constant_override("separation", 14)
	row.add_child(explanation)
	var heading := _label("Chef vestido", 25)
	heading.add_theme_font_override("font", UiTheme.font(UiTheme.BOLD))
	explanation.add_child(heading)
	explanation.add_child(_label("Confira a gola junto ao pescoço e o chapéu apoiado na cabeça.", 17))
	var note := _label("Prova parada. A personalização vem depois da aprovação do encaixe.", 14)
	note.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
	explanation.add_child(note)
	# O botão Chef do café também reabre esta prova; nunca expõe o editor de peças nesta sessão.
	var original = _cafe.hud.avatar_dialog()
	original.visibility_changed.connect(func() -> void:
		if original.visible:
			original.hide()
			_show_proof.call_deferred())
	_set_detail(_proof_detail)


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _set_detail(detail: bool) -> void:
	_proof_detail = detail
	_proof_portrait.custom_minimum_size = DETAIL_SIZE if detail else PORTRAIT_SIZE
	_proof_caption.text = "Vista ampliada" if detail else "Tamanho no jogo · 210 × 255"
	_proof_toggle.text = "Ver tamanho do jogo" if detail else "Ver ampliado"
	_fit_proof.call_deferred()


func _fit_proof() -> void:
	_proof_dialog.reset_size()
	if _proof_dialog.visible:
		_proof_dialog.move_to_center()


func _show_proof() -> void:
	if _proof_dialog == null or _cafe.is_dialog_open():
		return
	_proof_dialog.popup_centered()
	_proof_dialog.get_ok_button().grab_focus()


func _on_proof_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not _review or key == null or not key.pressed or key.echo or _proof_dialog == null:
		return
	if key.keycode == KEY_C:
		_show_proof()
	elif key.keycode == KEY_D:
		_set_detail(not _proof_detail)


func _capture_proof() -> void:
	if not await _photo(_output):
		return
	if _proof_request == "suite":
		_set_detail(true)
		if not await _photo(_output.get_basename() + "_detalhe.png"):
			return
	print("CHEF VESTIDO OK: ", _proof_request, " | ", _output)
	quit(0)


func _photo(path: String) -> bool:
	# Deixa o Container recalcular o tamanho antes de capturar o quadro realmente desenhado.
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png(path)
	if result != OK:
		_fail("Não foi possível gravar a foto: %s (%d)" % [path, result])
		return false
	print("Foto em ", path, " | retrato ", _proof_portrait.size)
	return true


func _fail(message: String) -> void:
	_proof_failed = true
	printerr("ERROR: ", message)
	quit(1)
