extends TestCase
## Sons gerados por código: dados válidos, duração certa, sem estourar o volume
## e sem estalo no começo e no fim das notas.


func _all_cues() -> Array[Resource]:
	var store := DefinitionStore.new(func(a: SoundCue, b: SoundCue) -> bool: return String(a.id) < String(b.id))
	store.load_dir(SoundBoard.SOUNDS_DIR, SoundCue)
	return store.all()


func test_every_game_cue_exists_and_is_valid() -> void:
	var ids := _all_cues().map(func(cue: SoundCue) -> StringName: return cue.id)
	for needed in [&"coin", &"dish_ready", &"level_up", &"purchase", &"error", &"achievement", &"tap"]:
		assert_true(needed in ids, "falta o som %s" % needed)
	for cue: SoundCue in _all_cues():
		assert_true(cue.is_valid(), "%s inválido" % cue.id)
		assert_true(cue.duration() <= 1.0, "%s: som de feedback precisa ser curto" % cue.id)


func test_render_has_the_right_length_and_stays_in_range() -> void:
	var cue := SoundCue.new()
	cue.id = &"x"
	cue.notes = PackedFloat32Array([440.0, 880.0])
	cue.note_duration = 0.1
	cue.gap = 0.05
	cue.waveform = SoundCue.Waveform.SQUARE
	cue.volume = 1.0
	var samples := SoundSynth.render_samples(cue, 1000)
	assert_eq(samples.size(), 100 + 50 + 100)
	var peak := 0.0
	for sample in samples:
		peak = maxf(peak, absf(sample))
	assert_true(peak <= 1.0 and peak > 0.5, "pico %.2f" % peak)


func test_notes_fade_in_and_out() -> void:
	var cue := SoundCue.new()
	cue.id = &"x"
	cue.waveform = SoundCue.Waveform.SQUARE
	cue.attack = 0.01
	cue.release = 0.02
	var samples := SoundSynth.render_samples(cue, 10000)
	assert_almost_eq(samples[0], 0.0, 0.001, "começa do silêncio")
	assert_true(absf(samples[samples.size() - 1]) < 0.05, "termina quase em silêncio")


func test_render_builds_a_playable_stream() -> void:
	var cue: SoundCue = load("res://data/sounds/coin.tres")
	var stream := SoundSynth.render(cue)
	assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)
	assert_eq(stream.data.size(), SoundSynth.render_samples(cue).size() * 2)
	assert_almost_eq(stream.get_length(), cue.duration(), 0.01)
