extends SceneTree
## Foto da cafeteria para conferência visual (precisa de janela: não use --headless).
##
## Uso (na pasta do projeto):
##   godot -s res://tools/screenshot.gd -- <save.json> <saida.png> [quadros] [zoom]
##
## Abre a cena com o save indicado (use uma cópia: o jogo salva sozinho), fecha as
## janelas de pergunta que aparecerem e grava a tela depois de alguns quadros.
## Sem save, começa um jogo novo numa pasta temporária.

var _cafe: Node
var _output := ""
var _frames := 90
var _zoom := 0.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var save_path := args[0] if args.size() > 0 else "user://screenshot/save.json"
	_output = args[1] if args.size() > 1 else "user://screenshot.png"
	if args.size() > 2:
		_frames = int(args[2])
	if args.size() > 3:
		_zoom = float(args[3])
	_cafe = load("res://scenes/cafe/cafe.tscn").instantiate()
	_cafe.save_service = load("res://core/save/save_service.gd").new(save_path)
	root.add_child(_cafe)


func _process(_delta: float) -> bool:
	for window: Window in _cafe.find_children("*", "Window", true, false):
		window.hide()
	if _zoom > 0.0:
		_cafe.get_viewport().get_camera_2d().zoom = Vector2(_zoom, _zoom)
	_frames -= 1
	if _frames > 0:
		return false
	var image := root.get_texture().get_image()
	image.save_png(_output)
	print("Foto em ", _output)
	return true
