class_name ChefAnimatedPortrait
extends Control
## Chef aprovado: textura única, malha contínua e substituição restrita aos olhos.
## Pausar congela; animated=false volta à imagem original. Ocultar não acumula tempo.

const BASE_PATH := "res://art/avatar/chef_vestido_v1.png"
const BLINK_PATH := "res://art/avatar/chef_blink_v1.json"
const MOTION_SHADER := preload("res://art/shaders/chef_portrait_motion.gdshader")
const REFERENCE_HEIGHT := 255.0
const GRID := Vector2i(10, 32)
const BREATH_PERIOD := 3.6
const BREATH_PIXELS := 0.35
const GREETING_DURATION := 1.1
const GREETING_DEGREES := 0.8
const GREETING_PIXELS := 0.6
const FIRST_BLINK := 2.8
const BLINK_GAPS := [3.7, 5.1, 4.3, 3.3]
const BLINK_DURATION := 0.19

var animated := true:
	set(value):
		animated = value
		if not animated:
			_reset_pose()
		_sync_activity()
var paused := false:
	set(value):
		paused = value
		_sync_activity()

var _texture: Texture2D
var _mesh := ArrayMesh.new()
var _motion_material: ShaderMaterial
var _owner_window: Window
var _elapsed := 0.0
var _greeting_age := -1.0
var _forced_blink := -1.0
var _manual_sample := false
var _blink_ready := false
var _blink := 0.0
var _angle := 0.0
var _offset := 0.0
var _deformed := false
var _rect := Rect2()
var _blink_config: Dictionary = {}


func _ready() -> void:
	_texture = load(BASE_PATH) as Texture2D
	_motion_material = ShaderMaterial.new()
	_motion_material.shader = MOTION_SHADER
	# A prova aprovada herda LINEAR da AcceptDialog: Window tem filtro próprio, distinto do projeto.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Toque para cumprimentar"
	resized.connect(_layout)
	gui_input.connect(_on_gui_input)
	_owner_window = get_window()
	_owner_window.visibility_changed.connect(_sync_activity)
	if FileAccess.file_exists(BLINK_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(BLINK_PATH))
		if parsed is Dictionary:
			configure_blink(parsed)
	_layout()
	_sync_activity()


func _exit_tree() -> void:
	if is_instance_valid(_owner_window) and _owner_window.visibility_changed.is_connected(_sync_activity):
		_owner_window.visibility_changed.disconnect(_sync_activity)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready():
		_sync_activity()


func _sync_activity() -> void:
	if not is_node_ready():
		return
	set_process(animated and not paused and not _manual_sample and is_visible_in_tree() and _owner_window.visible)


func _process(delta: float) -> void:
	_elapsed += delta
	if _greeting_age >= 0.0:
		_greeting_age += delta
		if _greeting_age >= GREETING_DURATION:
			_greeting_age = -1.0
	_apply_pose()


func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed):
		react()
		accept_event()


func react() -> void:
	if not is_processing():
		return
	_greeting_age = 0.0
	_apply_pose()


## Amostra absoluta para QA, independente do histórico; desliga avanço automático.
## blink=-1 usa o piscar automático; 0/0.5/1 forçam aberto/meio/fechado.
func set_sample(time_seconds: float, greeting_age := -1.0, blink := -1.0) -> void:
	_manual_sample = true
	_elapsed = maxf(0.0, time_seconds) if is_finite(time_seconds) else 0.0
	_greeting_age = greeting_age if is_finite(greeting_age) else -1.0
	_forced_blink = clampf(blink, 0.0, 1.0) if blink >= 0.0 and is_finite(blink) else -1.0
	_sync_activity()
	_apply_pose()


func resume_animation() -> void:
	_manual_sample = false
	_forced_blink = -1.0
	_sync_activity()


func _reset_pose() -> void:
	_elapsed = 0.0
	_greeting_age = -1.0
	_forced_blink = -1.0
	_manual_sample = false
	_apply_pose()


func _layout() -> void:
	if _texture == null or _motion_material == null:
		return
	var image_size := _texture.get_size()
	# Igual a TextureRect.KEEP_ASPECT_CENTERED: dimensões inteiras antes de centralizar.
	# Evita deslocamento subpixel na comparação com a prova aprovada (Godot texture_rect.cpp).
	var draw_width := int(image_size.x * size.y / image_size.y)
	var draw_height := int(size.y)
	if draw_width > size.x:
		draw_width = int(size.x)
		draw_height = int(image_size.y * draw_width / image_size.x)
	var draw_size := Vector2(draw_width, draw_height)
	_rect = Rect2((size - draw_size) * 0.5, draw_size)
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for y in GRID.y + 1:
		for x in GRID.x + 1:
			var uv := Vector2(float(x) / GRID.x, float(y) / GRID.y)
			var point := _rect.position + uv * _rect.size
			vertices.append(Vector3(point.x, point.y, 0.0))
			uvs.append(uv)
	for y in GRID.y:
		for x in GRID.x:
			var a := y * (GRID.x + 1) + x
			var b := a + 1
			var c := a + GRID.x + 1
			var d := c + 1
			indices.append_array(PackedInt32Array([a, b, c, b, d, c]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_motion_material.set_shader_parameter("image_origin", _rect.position)
	_motion_material.set_shader_parameter("image_size", _rect.size)
	_apply_pose()


func _apply_pose() -> void:
	if _motion_material == null:
		return
	_angle = 0.0
	_offset = 0.0
	_blink = 0.0
	if animated:
		var scale_factor := _rect.size.y / REFERENCE_HEIGHT
		_offset = -BREATH_PIXELS * (1.0 - cos(TAU * _elapsed / BREATH_PERIOD)) * 0.5 * scale_factor
		if _greeting_age >= 0.0 and _greeting_age < GREETING_DURATION:
			var greeting := sin(PI * _greeting_age / GREETING_DURATION)
			_angle = -deg_to_rad(GREETING_DEGREES) * greeting
			_offset += GREETING_PIXELS * greeting * scale_factor
		if _blink_ready:
			_blink = _forced_blink if _forced_blink >= 0.0 else blink_at(_elapsed)
	_deformed = absf(_angle) > 0.000001 or absf(_offset) > 0.000001
	_motion_material.set_shader_parameter("head_angle", _angle)
	_motion_material.set_shader_parameter("vertical_offset", _offset)
	_motion_material.set_shader_parameter("blink", _blink)
	# Pose neutra: o mesmo quadrilátero nativo, sem shader, que a imagem estática.
	material = _motion_material if _deformed or _blink > 0.0 else null
	queue_redraw()


func _draw() -> void:
	if _texture == null:
		return
	if _deformed:
		draw_mesh(_mesh, _texture)
	else:
		draw_texture_rect(_texture, _rect, false)


static func blink_at(time_seconds: float) -> float:
	if time_seconds < FIRST_BLINK:
		return 0.0
	var period := 0.0
	for gap: float in BLINK_GAPS:
		period += gap
	var age := fposmod(time_seconds - FIRST_BLINK, period)
	for gap: float in BLINK_GAPS:
		if age < gap:
			break
		age -= gap
	if age >= BLINK_DURATION:
		return 0.0
	if age < 0.015:
		return 0.5 * smoothstep(0.0, 0.015, age)
	if age < 0.035:
		return 0.5
	if age < 0.045:
		return lerpf(0.5, 1.0, smoothstep(0.035, 0.045, age))
	if age < 0.120:
		return 1.0
	if age < 0.130:
		return lerpf(1.0, 0.5, smoothstep(0.120, 0.130, age))
	if age < 0.175:
		return 0.5
	return 0.5 * (1.0 - smoothstep(0.175, BLINK_DURATION, age))


## Contrato v1: retângulos xywh normalizados, separados por olho do observador.
## Configuração inválida mantém o piscar desativado; a base nunca é substituída.
func configure_blink(config: Dictionary) -> bool:
	_blink_ready = false
	_blink_config.clear()
	_apply_pose()
	if _motion_material == null or config.get("version", 0) != 1 or config.get("base_texture", "") != BASE_PATH:
		return false
	var eyes = config.get("eyes", {})
	if not eyes is Dictionary:
		return false
	for eye: String in ["left", "right"]:
		var entry = eyes.get(eye, {})
		if not entry is Dictionary:
			return false
		for field: String in ["destination", "half_source", "closed_source"]:
			if not _valid_rect(entry.get(field, null)):
				return false
	var feather := float(config.get("feather", 0.10))
	if not is_finite(feather) or feather <= 0.0 or feather > 0.5:
		return false
	var half_path := String(config.get("half_texture", ""))
	var closed_path := String(config.get("closed_texture", ""))
	if half_path.is_empty() or closed_path.is_empty() or not ResourceLoader.exists(half_path) or not ResourceLoader.exists(closed_path):
		return false
	var half := load(half_path) as Texture2D
	var closed := load(closed_path) as Texture2D
	if half == null or closed == null:
		return false
	_motion_material.set_shader_parameter("half_texture", half)
	_motion_material.set_shader_parameter("closed_texture", closed)
	_motion_material.set_shader_parameter("eye_feather", feather)
	for eye: String in ["left", "right"]:
		for field: String in ["destination", "half_source", "closed_source"]:
			var values: Array = eyes[eye][field]
			_motion_material.set_shader_parameter(eye + "_" + field, Vector4(values[0], values[1], values[2], values[3]))
	_blink_config = config.duplicate(true)
	_blink_ready = true
	_apply_pose()
	return true


static func _valid_rect(value) -> bool:
	if not value is Array or value.size() != 4:
		return false
	for number in value:
		if not (number is float or number is int) or not is_finite(float(number)):
			return false
	return value[0] >= 0.0 and value[1] >= 0.0 and value[2] > 0.0 and value[3] > 0.0 \
		and value[0] + value[2] <= 1.0 and value[1] + value[3] <= 1.0


func visual_state() -> Dictionary:
	return {"base_path": BASE_PATH, "animated": animated, "paused": paused, "active": is_processing(),
		"elapsed": _elapsed, "greeting_age": _greeting_age, "blink": _blink, "blink_ready": _blink_ready,
		"angle": _angle, "offset": _offset, "deformed": _deformed, "manual_sample": _manual_sample,
		"image_rect": _rect, "material_id": _motion_material.get_instance_id() if _motion_material != null else 0}
