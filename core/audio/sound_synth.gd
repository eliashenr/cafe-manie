class_name SoundSynth
extends RefCounted
## Transforma um SoundCue em amostras de áudio (PCM 16 bits, mono).

const MIX_RATE := 22050


## Amostras entre -1 e 1.
static func render_samples(cue: SoundCue, mix_rate := MIX_RATE) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	var per_note := int(cue.note_duration * mix_rate)
	var per_gap := int(cue.gap * mix_rate)
	for n in cue.notes.size():
		var frequency: float = cue.notes[n]
		for i in per_note:
			var t := float(i) / mix_rate
			samples.append(_wave(cue.waveform, frequency * t) * _envelope(cue, t) * cue.volume)
		if n < cue.notes.size() - 1:
			for i in per_gap:
				samples.append(0.0)
	return samples


static func render(cue: SoundCue) -> AudioStreamWAV:
	var samples := render_samples(cue)
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


## Uma onda de período 1 no ponto [param phase] (em ciclos).
static func _wave(waveform: SoundCue.Waveform, phase: float) -> float:
	var cycle := phase - floorf(phase)
	match waveform:
		SoundCue.Waveform.SQUARE:
			return 1.0 if cycle < 0.5 else -1.0
		SoundCue.Waveform.TRIANGLE:
			return 4.0 * absf(cycle - 0.5) - 1.0
	return sin(TAU * cycle)


static func _envelope(cue: SoundCue, t: float) -> float:
	var level := 1.0
	if cue.attack > 0.0 and t < cue.attack:
		level = t / cue.attack
	var until_end := cue.note_duration - t
	if cue.release > 0.0 and until_end < cue.release:
		level = minf(level, until_end / cue.release)
	return clampf(level, 0.0, 1.0)
