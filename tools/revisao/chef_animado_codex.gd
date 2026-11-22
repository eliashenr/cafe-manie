extends "res://tools/revisao/chef_vestido_codex.gd"
## DT-110: extensão isolada da prova aprovada, sem editar a prova estática nem o avatar de produção.
## CLI: <saida.png> mostruario dia foto tamanho [tamanho|detalhe|suite|movimento]
## suite: original/open/half/closed neutros e greetmax, em210x255 e336x408; mais capa.
## movimento: capa +180 PNGs _movimento_000..179, a30fps; cumprimento em0.8s e piscar automático.
## Revisão: C reabre, D amplia, espaço pausa/retoma, G cumprimenta, N dia/noite.

class MotionInput extends Node:
	var handle_key: Callable

	func _input(event: InputEvent) -> void:
		# Window.window_input vem antes do reset interno de handled; _input antecede a GUI.
		if handle_key.is_valid() and handle_key.call(event):
			get_viewport().set_input_as_handled()


const MotionPortrait := preload("res://scenes/ui/chef_animated_portrait.gd")
const MOTION_FRAMES := 180
const MOTION_FPS := 30.0
const GREET_AT := 0.8

var _motion
var _motion_request := "tamanho"
var _pause_button: Button
var _greet_button: Button
var _compare_button: Button
var _motion_captures := 0


func _initialize() -> void:
	super()
	if _proof_failed:
		return
	var args := OS.get_cmdline_user_args()
	_motion_request = args[5] if args.size() > 5 else _proof_request
	if _motion_request not in ["tamanho", "detalhe", "suite", "movimento"]:
		_fail("Revisão de movimento desconhecida: " + _motion_request)
		return
	root.title = "Chef animado · espaço: pausar · G: cumprimentar · D: detalhe · C: chef · sem salvar"


func _create_proof() -> void:
	super()
	_proof_dialog.title = "Chef — movimento e encaixe"
	_proof_portrait.texture = null
	_motion = MotionPortrait.new()
	_motion.name = "ChefAnimatedPortrait"
	_motion.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_proof_portrait.add_child(_motion)
	var shortcuts := MotionInput.new()
	shortcuts.name = "ChefMotionInput"
	shortcuts.handle_key = _on_motion_input
	_proof_dialog.add_child(shortcuts)
	var explanation: VBoxContainer
	for label: Label in _proof_dialog.find_children("*", "Label", true, false):
		if label.text == "Chef vestido":
			label.text = "Chef em movimento"
			label.add_theme_font_size_override("font_size", 22)
			explanation = label.get_parent() as VBoxContainer
		elif label.text.begins_with("Confira a gola"):
			label.text = "Toque no chef para cumprimentar."
		elif label.text.begins_with("Prova parada."):
			label.text = "Respiração discreta. Compare com o original aprovado."
	if explanation == null:
		_fail("O painel da prova estática mudou; revisar a integração do chef animado.")
		return
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	explanation.add_child(actions)
	_pause_button = _motion_button("PauseChefButton", "Pausar", actions, _toggle_pause)
	_greet_button = _motion_button("GreetChefButton", "Cumprimentar", actions, func() -> void: _motion.react())
	_compare_button = _motion_button("CompareChefButton", "Ver original aprovado", explanation, _toggle_comparison)
	_compare_button.toggle_mode = true
	UiTheme.role(_compare_button, UiTheme.GHOST_BUTTON)
	var stage := _proof_dialog.find_child("Stage", true, false) as Control
	stage.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if _motion_request == "detalhe":
		_set_detail(true)
	_sync_controls()
	_fit_proof.call_deferred()


func _motion_button(button_name: String, caption: String, parent: Node, action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = caption
	button.custom_minimum_size.y = UiTheme.MIN_TOUCH
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _toggle_pause() -> void:
	if _motion == null or not _motion.animated:
		return
	_motion.paused = not _motion.paused
	_sync_controls()


func _toggle_comparison() -> void:
	_set_original(_compare_button.button_pressed)


func _set_original(original: bool) -> void:
	_motion.animated = not original
	if not original:
		_motion.resume_animation()
	_compare_button.set_pressed_no_signal(original)
	_sync_controls()


func _sync_controls() -> void:
	_pause_button.text = "Retomar" if _motion.paused else "Pausar"
	_pause_button.disabled = not _motion.animated
	_greet_button.disabled = not _motion.animated or _motion.paused
	_compare_button.text = "Voltar ao movimento" if not _motion.animated else "Ver original aprovado"


func _on_motion_input(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if not _review or key == null or _motion == null or not _proof_dialog.visible:
		return false
	if key.keycode not in [KEY_SPACE, KEY_G]:
		return false
	# Consome também soltura/repetição para nenhum botão focado receber metade da tecla.
	if key.pressed and not key.echo:
		if key.keycode == KEY_SPACE:
			_toggle_pause()
		else:
			_motion.react()
	return true


func _capture_proof() -> void:
	_motion.paused = false
	_motion.set_sample(0.0, -1.0, 0.0)
	if not await _motion_photo(""):
		return
	if _motion_request == "suite":
		for detail: bool in [false, true]:
			_set_detail(detail)
			var size_name := "detalhe" if detail else "tamanho"
			for pose: String in ["original", "open", "half", "closed", "greetmax"]:
				_set_original(pose == "original")
				var closure: float = {"half": 0.5, "closed": 1.0}.get(pose, 0.0)
				var greeting := MotionPortrait.GREETING_DURATION * 0.5 if pose == "greetmax" else -1.0
				_motion.set_sample(0.0, greeting, closure)
				if not await _motion_photo(size_name + "_" + pose):
					return
	elif _motion_request == "movimento":
		for frame in MOTION_FRAMES:
			var time := float(frame) / MOTION_FPS
			var greeting := time - GREET_AT
			if greeting < 0.0 or greeting >= MotionPortrait.GREETING_DURATION:
				greeting = -1.0
			_motion.set_sample(time, greeting)
			if not await _motion_photo("movimento_%03d" % frame):
				return
	print("CHEF ANIMADO OK: ", _motion_request, " | ", _motion_captures, " capturas | ", _output)
	quit(0)


func _motion_photo(suffix: String) -> bool:
	var path := _output if suffix.is_empty() else _output.get_basename() + "_" + suffix + ".png"
	if not await _photo(path):
		return false
	_motion_captures += 1
	return true
