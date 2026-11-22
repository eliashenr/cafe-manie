extends "res://tools/revisao/clientes_codex.gd"
## Revisão completa em memória: fluxo real de clientes, sem SaveService.
## N: dia/noite; 1/2: lotes de clientes; 0: todos; C: próxima coleção cultural.
## foto.ps1: -Script res://tools/revisao/visual_codex.gd -Variant mostruario -Mode fixa
## -Extra colecao:japao ou colecao:brasil fotografa todos os clientes com a coleção escolhida.
## Os IDs reais do catálogo (japones/brasileiro etc.) também são aceitos; -Extra mostruario mantém a mistura.

const COLLECTIONS: Array[StringName] = [
	&"japones", &"brasileiro", &"italiano", &"frances", &"mexicano", &"americano",
	&"country", &"festa", &"anos70", &"anos80", &"anos2010", &"balada",
]
const COLLECTION_NAMES: Array[String] = [
	"Japão", "Brasil", "Itália", "França", "México", "Americano",
	"Country", "Festa", "Anos 70", "Anos 80", "Anos 2010", "Balada",
]
const COLLECTION_ALIASES := {"japao": "japones", "brasil": "brasileiro", "italia": "italiano",
	"franca": "frances", "mexico": "mexicano"}

var _collection_request := ""
var _collection_index := -1
var _visual_batch := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 4 and args[4].begins_with("colecao:"):
		_collection_request = args[4].get_slice(":", 1).to_lower()
		_collection_request = COLLECTION_ALIASES.get(_collection_request, _collection_request)
	super()


func _prepare_stage() -> bool:
	if not super():
		return false
	if not _collection_request.is_empty():
		var index := COLLECTIONS.find(StringName(_collection_request))
		if index < 0 or not _apply_collection(index):
			printerr("ERROR: coleção de revisão inválida: ", _collection_request)
			return false
	_set_review_title(_visual_batch)
	return true


## A ocupação não muda: só trocamos definições de mesma categoria e footprint1×1.
## Este atalho existe apenas na ferramenta de revisão, fora das operações do jogo salvo.
func _apply_collection(index: int) -> bool:
	var collection := COLLECTIONS[index]
	var choices := {FurnitureDefinition.Category.TABLE: [], FurnitureDefinition.Category.SEATING: []}
	for definition: FurnitureDefinition in _cafe.simulation.furniture.all():
		if definition.collection == collection and definition.footprint == Vector2i.ONE \
				and choices.has(definition.category):
			choices[definition.category].append(definition)
	for category in choices:
		if choices[category].is_empty():
			printerr("ERROR: coleção sem mesa ou assento1×1: ", collection)
			return false
	var counts := {FurnitureDefinition.Category.TABLE: 0, FurnitureDefinition.Category.SEATING: 0}
	for placement in _cafe.layout.placements():
		var category = placement.definition.category
		if placement.definition.footprint != Vector2i.ONE or not choices.has(category):
			continue
		var candidates: Array = choices[category]
		placement.definition = candidates[int(counts[category]) % candidates.size()]
		counts[category] += 1
	_collection_index = index
	# Atualiza as vistas e o HUD sem disparar recompensas de colocação ou alterar a navegação.
	_cafe.world_layer.sync()
	_cafe.world_layer.refresh(_cafe.simulation)
	_cafe.hud.refresh()
	_set_review_title(_visual_batch)
	print("COLECAO VISUAL ", collection, " | mesas ", counts[FurnitureDefinition.Category.TABLE],
		" | assentos ", counts[FurnitureDefinition.Category.SEATING])
	return true


func _set_review_title(batch: int) -> void:
	_visual_batch = batch
	var collection := "Mostruário misto" if _collection_index < 0 else COLLECTION_NAMES[_collection_index]
	var group := "12 clientes" if batch == 0 else ("clientes01–06" if batch == 1 else "clientes07–12")
	root.title = "Revisão Visual · %s · %s · C: coleção | N: dia/noite | 1/2: lotes | 0: todos · sem salvar" % [collection, group]


func _on_review_input(event: InputEvent) -> void:
	# Digitar o nome do café ou operar uma janela não deve acionar atalhos da revisão.
	if _cafe != null and _cafe.is_dialog_open():
		return
	super(event)
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not _stage_ready:
		return
	if key.keycode == KEY_C:
		_apply_collection((_collection_index + 1) % COLLECTIONS.size())
		root.set_input_as_handled()


func _capture_suite() -> void:
	if _collection_request.is_empty() and _request != "mostruario":
		await super()
		return
	for _frame in WARMUP_FRAMES:
		await process_frame
	_show_overview(0)
	await create_timer(Juice.FADE_IN_TIME + 0.15).timeout
	if not await _write_capture(_output):
		quit(1)
		return
	print("REVISAO VISUAL OK: ", "Mostruário misto" if _collection_index < 0 else COLLECTION_NAMES[_collection_index], " | ", _output)
	quit(0)
