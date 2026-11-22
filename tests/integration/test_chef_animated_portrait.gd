extends TestCase
## DT-110: a prova animada conserva o chef aprovado e não avança enquanto pausada ou oculta.

const Portrait = preload("res://scenes/ui/chef_animated_portrait.gd")
const APPROVED_SOURCE := "res://art/avatar/chef_vestido_v1.png"


func _portrait(animate := false, parent: Node = null) -> ChefAnimatedPortrait:
	var portrait := Portrait.new()
	portrait.size = Vector2(210, 255)
	portrait.animated = animate
	if parent == null:
		add_to_tree(portrait)
	else:
		parent.add_child(portrait)
	return portrait


func _wait_frames(count := 3) -> void:
	for _frame in count:
		await tree.process_frame


func test_static_mode_and_invalid_blink_restore_the_approved_original() -> void:
	var source_hash := FileAccess.get_sha256(APPROVED_SOURCE)
	assert_false(source_hash.is_empty(), "a fonte aprovada está disponível")
	var portrait := _portrait()
	var original := portrait.visual_state()
	assert_eq(original["base_path"], APPROVED_SOURCE)
	assert_false(portrait.is_processing(), "modo estático não avança")
	assert_true(portrait.material == null, "a fonte neutra usa o desenho nativo sem shader")
	var original_rect: Rect2 = original["image_rect"]
	assert_true(original_rect.has_area(), "a fonte ocupa uma área visível")
	assert_true(Rect2(Vector2.ZERO, portrait.size).encloses(original_rect), "a imagem cabe inteira no retrato")
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/avatar/chef_blink_v1.json"))
	assert_true(portrait.configure_blink(config), "a configuração instalada habilita a piscada")
	portrait.animated = true
	portrait.set_sample(0.0, -1.0, 1.0)
	assert_true(float(portrait.visual_state()["blink"]) > 0.0, "pálpebras realmente entram antes do teste de retorno")
	assert_true(portrait.material != null)
	assert_false(portrait.configure_blink({}), "configuração ausente é recusada")
	assert_almost_eq(float(portrait.visual_state()["blink"]), 0.0)
	assert_true(portrait.material == null, "configuração inválida remove imediatamente a sobreposição")
	assert_true(portrait.configure_blink(config))
	portrait.set_sample(0.9, 0.35, 1.0)
	assert_true(portrait.visual_state()["deformed"], "o retrato estava em movimento antes de voltar ao original")
	portrait.animated = false
	var restored := portrait.visual_state()
	for field in ["base_path", "image_rect", "elapsed", "greeting_age", "blink", "angle", "offset", "deformed"]:
		assert_eq(restored[field], original[field], "modo estático restaura " + field)
	assert_true(portrait.material == null)
	assert_false(portrait.is_processing())
	portrait.react()
	await _wait_frames()
	assert_eq(portrait.visual_state(), restored, "toque e quadros reais não alteram o modo estático")
	assert_eq(FileAccess.get_sha256(APPROVED_SOURCE), source_hash, "a fonte aprovada permanece intacta")


func test_sampling_is_history_independent_and_pause_freezes_until_resumed() -> void:
	var portrait := _portrait(true)
	portrait.set_sample(6.1, 0.35, 0.5)
	var expected := portrait.visual_state()
	portrait.set_sample(0.2, -1.0, 0.0)
	portrait.set_sample(8.7, 0.8, 1.0)
	portrait.set_sample(6.1, 0.35, 0.5)
	assert_eq(portrait.visual_state(), expected, "amostra absoluta independe dos quadros anteriores")
	assert_false(portrait.is_processing(), "amostragem manual não avança automaticamente")
	await _wait_frames()
	assert_eq(portrait.visual_state(), expected)
	portrait.paused = true
	portrait.resume_animation()
	var frozen := portrait.visual_state()
	assert_false(portrait.is_processing(), "sair da amostragem não ignora a pausa")
	portrait.react()
	await _wait_frames()
	assert_eq(portrait.visual_state(), frozen, "pausa preserva o quadro mesmo com uma tentativa de cumprimento")
	portrait.paused = false
	assert_true(portrait.is_processing(), "retomar habilita o avanço pelo motor")
	await _wait_frames()
	assert_true(float(portrait.visual_state()["elapsed"]) > float(frozen["elapsed"]), "o relógio avança após retomar")
	portrait.set_sample(6.1, 0.35, 0.5)
	assert_eq(portrait.visual_state(), expected, "o avanço automático também não contamina uma nova amostra absoluta")


func test_hidden_window_parent_and_portrait_freeze_without_accumulating_time() -> void:
	var window := Window.new()
	window.visible = false
	add_to_tree(window)
	var parent := Control.new()
	window.add_child(parent)
	var portrait := _portrait(true, parent)
	portrait.set_sample(4.0, 0.35, 0.5)
	portrait.resume_animation()
	var frozen := portrait.visual_state()
	assert_false(portrait.is_processing(), "nascer numa Window oculta não inicia processamento")
	await _wait_frames()
	assert_eq(portrait.visual_state(), frozen)
	window.show()
	assert_true(portrait.is_processing())
	assert_eq(portrait.visual_state()["elapsed"], frozen["elapsed"], "mostrar não acrescenta o tempo oculto")
	await _wait_frames()
	assert_true(float(portrait.visual_state()["elapsed"]) > float(frozen["elapsed"]))
	window.hide()
	frozen = portrait.visual_state()
	assert_false(portrait.is_processing(), "ocultar a Window interrompe o retrato")
	await _wait_frames()
	assert_eq(portrait.visual_state(), frozen)
	window.show()
	assert_true(portrait.is_processing())
	assert_eq(portrait.visual_state()["elapsed"], frozen["elapsed"])
	parent.hide()
	frozen = portrait.visual_state()
	assert_false(portrait.is_processing(), "um ancestral Control oculto também interrompe")
	await _wait_frames()
	assert_eq(portrait.visual_state(), frozen)
	parent.show()
	assert_true(portrait.is_processing())
	assert_eq(portrait.visual_state()["elapsed"], frozen["elapsed"])
	portrait.hide()
	frozen = portrait.visual_state()
	assert_false(portrait.is_processing())
	await _wait_frames()
	assert_eq(portrait.visual_state(), frozen)
	portrait.show()
	assert_true(portrait.is_processing())
	assert_eq(portrait.visual_state()["elapsed"], frozen["elapsed"])


func test_reaction_finishes_without_moving_the_hit_area_or_another_instance() -> void:
	var active := _portrait(true)
	var other := _portrait(true)
	other.set_sample(0.6, 0.4, 0.5)
	other.paused = true
	other.resume_animation()
	var other_before := other.visual_state()
	assert_true(active.visual_state()["material_id"] != other_before["material_id"], "cada retrato tem seu material")
	var other_material := other.material as ShaderMaterial
	assert_true(other_material != null)
	var other_blink = other_material.get_shader_parameter("blink")
	var other_angle = other_material.get_shader_parameter("head_angle")
	var other_offset = other_material.get_shader_parameter("vertical_offset")
	var hit_area := active.get_rect()
	active.react()
	await tree.create_timer(0.08).timeout
	assert_true(float(active.visual_state()["greeting_age"]) > 0.0, "cumprimento avança em quadros reais")
	assert_true(absf(float(active.visual_state()["angle"])) > 0.000001, "o cumprimento produz resposta visual")
	active.react()
	assert_almost_eq(float(active.visual_state()["greeting_age"]), 0.0, 0.001, "novo toque reinicia, sem somar deformações")
	await tree.create_timer(1.25).timeout
	assert_true(float(active.visual_state()["greeting_age"]) < 0.0, "o cumprimento termina")
	assert_almost_eq(float(active.visual_state()["angle"]), 0.0, 0.000001, "a inclinação não fica acumulada")
	assert_eq(active.get_rect(), hit_area, "a área de toque permanece parada")
	assert_eq(other.visual_state(), other_before, "a outra instância permanece no quadro congelado")
	assert_eq(other_material.get_shader_parameter("blink"), other_blink)
	assert_eq(other_material.get_shader_parameter("head_angle"), other_angle)
	assert_eq(other_material.get_shader_parameter("vertical_offset"), other_offset)
