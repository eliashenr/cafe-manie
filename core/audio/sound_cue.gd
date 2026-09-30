class_name SoundCue
extends Resource
## Um som de feedback gerado por código (res://data/sounds). Sons originais,
## sem arquivo de áudio: uma sequência de notas curtas com envelope.

enum Waveform { SINE, TRIANGLE, SQUARE }

@export var id: StringName
## Frequência de cada nota, em Hz, tocadas uma depois da outra.
@export var notes: PackedFloat32Array = PackedFloat32Array([880.0])
## Duração de cada nota, em segundos.
@export var note_duration := 0.08
## Silêncio entre notas, em segundos.
@export var gap := 0.0
@export var waveform := Waveform.SINE
## Subida e descida do volume de cada nota, em segundos (evita estalos).
@export var attack := 0.005
@export var release := 0.05
## Volume, de 0 a 1.
@export_range(0.0, 1.0) var volume := 0.5


func is_valid() -> bool:
	return id != &"" and not notes.is_empty() and note_duration > 0.0 and gap >= 0.0 \
		and attack >= 0.0 and release >= 0.0 and volume > 0.0 and volume <= 1.0


func duration() -> float:
	return notes.size() * note_duration + maxi(notes.size() - 1, 0) * gap
