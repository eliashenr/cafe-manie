"""Música ambiente do Café Manie: bossa nova suave de restaurante, composta e sintetizada por código.

Tudo aqui é original (harmonia, melodia e timbres) e sai sempre igual: o mesmo código gera o mesmo arquivo.
Sem bibliotecas além do Python: piano elétrico por FM, contrabaixo dedilhado, vibrafone, vassourinha,
caxixi e aro de caixa, com reverberação de salão. O fim emenda no começo (a faixa toca em loop).

    python tools/music/compose_bossa.py          # grava art/music/bossa_do_cafe.wav

Forma: 16 compassos em fá maior, tocados três vezes: a melodia no vibrafone, um solo suave do piano
elétrico, e a melodia de novo (a primeira metade uma oitava acima).
"""
import math
import os
import random
import struct
import wave

RATE = 32000          # Hz, mono: suave e leve para o jogo
BPM = 88
BEAT = 60.0 / BPM
BAR = 4 * BEAT
TAIL = 4.0            # segundos de sobra para as notas que soam além do fim (dobradas no começo)
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "art", "music", "bossa_do_cafe.wav"))

NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8,
        "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def midi(name):
    """'A4' -> 69."""
    pitch, octave = name[:-1], int(name[-1])
    return 12 * (octave + 1) + NOTE[pitch]


def freq(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


# --- Harmonia ------------------------------------------------------------------------------
# (compasso, tempo de início, duração em tempos, acorde). Vozes do piano sem a fundamental (o baixo faz).
VOICINGS = {
    "Fmaj9": ["A3", "C4", "E4", "G4"], "Gm9": ["Bb3", "D4", "F4", "A4"], "C13": ["Bb3", "D4", "E4", "A4"],
    "Am9": ["C4", "E4", "G4", "B4"], "D7b9": ["F#3", "C4", "Eb4", "A4"], "F9": ["A3", "C4", "Eb4", "G4"],
    "Bbmaj9": ["D4", "F4", "A4", "C5"], "Bbm6": ["Db4", "F4", "G4", "Bb4"], "C9sus": ["Bb3", "D4", "F4", "G4"],
}
ROOTS = {"Fmaj9": "F2", "Gm9": "G2", "C13": "C2", "Am9": "A2", "D7b9": "D2", "F9": "F2", "Bbmaj9": "Bb1",
         "Bbm6": "Bb1", "C9sus": "C2"}
FIFTHS = {"Fmaj9": "C3", "Gm9": "D3", "C13": "G2", "Am9": "E3", "D7b9": "A2", "F9": "C3", "Bbmaj9": "F2",
          "Bbm6": "F2", "C9sus": "G2"}
FORM = [  # um acorde por compasso, ou dois (meio a meio)
    ["Fmaj9"], ["Fmaj9"], ["Gm9"], ["C13"], ["Am9"], ["D7b9"], ["Gm9"], ["C13"],
    ["Fmaj9"], ["F9"], ["Bbmaj9"], ["Bbm6"], ["Am9"], ["D7b9"], ["Gm9", "C13"], ["Fmaj9", "C9sus"],
]

# --- Melodia (vibrafone) -------------------------------------------------------------------
# Por compasso: (nota, início em tempos, duração em tempos).
MELODY = [
    [("A4", 0, 1.5), ("G4", 1.5, 0.5), ("A4", 2, 1), ("C5", 3, 1)],
    [("E5", 0, 2.5), ("D5", 2.5, 0.5), ("C5", 3, 1)],
    [("D5", 0, 1.5), ("Bb4", 1.5, 0.5), ("A4", 2, 1), ("F4", 3, 1)],
    [("E4", 0, 1.5), ("G4", 1.5, 0.5), ("Bb4", 2, 1.5)],
    [("C5", 0, 1.5), ("B4", 1.5, 0.5), ("C5", 2, 1), ("E5", 3, 1)],
    [("F#5", 0, 1.5), ("Eb5", 1.5, 0.5), ("D5", 2, 1), ("C5", 3, 1)],
    [("Bb4", 0, 2), ("A4", 2, 1), ("G4", 3, 1)],
    [("E4", 0, 1), ("F4", 1, 1), ("G4", 2, 2)],
    [("A4", 0, 1), ("C5", 1, 1), ("E5", 2, 1.5), ("D5", 3.5, 0.5)],
    [("Eb5", 0, 2), ("D5", 2, 1), ("C5", 3, 1)],
    [("D5", 0, 1.5), ("C5", 1.5, 0.5), ("A4", 2, 1), ("F4", 3, 1)],
    [("Db5", 0, 1.5), ("C5", 1.5, 0.5), ("Bb4", 2, 1.5)],
    [("C5", 0, 1), ("E5", 1, 1), ("G5", 2, 1.5), ("E5", 3.5, 0.5)],
    [("F#5", 0, 1), ("Eb5", 1, 1), ("C5", 2, 1), ("A4", 3, 1)],
    [("Bb4", 0, 1), ("A4", 1, 1), ("G4", 2, 1), ("E4", 3, 1)],
    [("F4", 0, 3)],
]

# Volumes de cada parte, medidos com compose(only=...): melodia na frente (cerca de -3 dB do total),
# piano e contrabaixo atrás (-6 dB), percussão discreta (-17 dB).
PIANO_GAIN = 0.09
BASS_GAIN = 0.13
VIBES_GAIN = 0.12
SWISH_GAIN = 0.22
SHAKER_GAIN = 0.06
RIM_GAIN = 0.08

# Solo do piano (segunda volta): notas do acorde e tensões, andando aos poucos, em ritmos de bossa.
SOLO_GAIN = 0.16
SOLO_RHYTHMS = [
    [(0, 1), (1, 0.5), (1.5, 1), (2.5, 0.5), (3, 1)],
    [(0, 1.5), (1.5, 0.5), (2, 1), (3, 0.5), (3.5, 0.5)],
    [(0.5, 0.5), (1, 1), (2, 1.5), (3.5, 0.5)],
    [(0, 2), (2.5, 0.5), (3, 1)],
]
SCALES = {  # notas boas sobre cada acorde (classes de altura)
    "Fmaj9": [5, 7, 9, 0, 4], "Gm9": [7, 10, 2, 5, 9], "C13": [0, 4, 7, 10, 2, 9], "Am9": [9, 0, 4, 7, 11],
    "D7b9": [2, 6, 9, 0, 3], "F9": [5, 9, 0, 3, 7], "Bbmaj9": [10, 2, 5, 9, 0], "Bbm6": [10, 1, 5, 7],
    "C9sus": [0, 5, 7, 10, 2],
}
SOLO_LOW, SOLO_HIGH = 60, 81  # C4 a A5
CHORUSES = ("melodia", "solo", "melodia_alta")

# Ritmo do piano (batida de bossa em colcheias, ao longo de dois compassos) e do aro (clave 3-2).
COMP_EIGHTHS = [(0, 0.8), (3, 0.5), (6, 0.8), (10, 0.5), (13, 0.8)]
RIM_EIGHTHS = [0, 3, 6, 10, 12]


# --- Timbres -------------------------------------------------------------------------------

def envelope(t, attack, decay, length, release=0.06):
    """Ataque linear, queda exponencial e soltura no fim da nota."""
    if t < attack:
        level = t / attack
    else:
        level = math.exp(-(t - attack) / decay)
    if t > length:
        level *= max(0.0, 1.0 - (t - length) / release)
    return level


_cache = {}


def electric_piano(m, beats):
    """Piano elétrico por FM: brilho no ataque que amacia, e um sininho no começo."""
    key = ("ep", m, beats)
    if key in _cache:
        return _cache[key]
    f = freq(m)
    length = beats * BEAT
    n = int((length + 0.08) * RATE)
    tau = 2 * math.pi
    out = []
    for i in range(n):
        t = i / RATE
        env = envelope(t, 0.004, 1.1, length, 0.08)
        index = 1.6 * math.exp(-t / 0.25) + 0.25
        mod = math.sin(tau * f * t)
        tone = math.sin(tau * f * t + index * mod)
        bell = 0.12 * math.sin(tau * f * 6.98 * t) * math.exp(-t / 0.06)
        out.append((tone + bell) * env)
    _cache[key] = out
    return out


def bass(m, beats):
    """Contrabaixo dedilhado: fundamental redonda, um pouco de harmônico e o estalo do dedo."""
    key = ("bass", m, beats)
    if key in _cache:
        return _cache[key]
    f = freq(m)
    length = beats * BEAT
    n = int((length + 0.06) * RATE)
    tau = 2 * math.pi
    rng = random.Random(m)
    out = []
    for i in range(n):
        t = i / RATE
        env = envelope(t, 0.006, 0.9, length * 0.95, 0.06)
        tone = math.sin(tau * f * t) + 0.35 * math.sin(tau * 2 * f * t) * math.exp(-t / 0.4) + 0.08 * math.sin(tau * 3 * f * t)
        pluck = (rng.random() * 2 - 1) * 0.18 * math.exp(-t / 0.008)
        out.append(tone * env + pluck)
    _cache[key] = out
    return out


def vibraphone(m, beats):
    """Vibrafone: barra de metal com o tremolo do ventilador e uma cauda longa."""
    key = ("vib", m, beats)
    if key in _cache:
        return _cache[key]
    f = freq(m)
    length = beats * BEAT
    n = int((length + 1.2) * RATE)
    tau = 2 * math.pi
    out = []
    for i in range(n):
        t = i / RATE
        env = envelope(t, 0.003, 1.6, length + 0.9, 0.3)
        tremolo = 1.0 + 0.22 * math.sin(tau * 5.2 * t)
        tone = math.sin(tau * f * t) + 0.22 * math.sin(tau * 4.0 * f * t) * math.exp(-t / 0.35) + 0.05 * math.sin(tau * 10.0 * f * t) * math.exp(-t / 0.05)
        out.append(tone * env * tremolo)
    _cache[key] = out
    return out


class Noise:
    """Ruído com filtros de um polo (para vassourinha, caxixi e aro)."""

    def __init__(self, seed):
        self.rng = random.Random(seed)

    def burst(self, seconds, attack, decay, low_pass, high_pass):
        n = int(seconds * RATE)
        out = []
        lp = hp_in = hp_out = 0.0
        a_lp = math.exp(-2 * math.pi * low_pass / RATE)
        a_hp = math.exp(-2 * math.pi * high_pass / RATE)
        for i in range(n):
            t = i / RATE
            x = self.rng.random() * 2 - 1
            lp = (1 - a_lp) * x + a_lp * lp
            hp_out = a_hp * (hp_out + lp - hp_in)
            hp_in = lp
            env = (t / attack) if t < attack else math.exp(-(t - attack) / decay)
            out.append(hp_out * env)
        return out


def rim_click(noise):
    tau = 2 * math.pi
    click = noise.burst(0.06, 0.001, 0.012, 6000, 900)
    return [c + 0.6 * math.sin(tau * 1700 * i / RATE) * math.exp(-i / RATE / 0.01) for i, c in enumerate(click)]


# --- Mixagem -------------------------------------------------------------------------------

def add(buffer, at_seconds, samples, gain):
    start = int(at_seconds * RATE)
    end = min(len(buffer), start + len(samples))
    if end <= start:
        return
    buffer[start:end] = [b + gain * s for b, s in zip(buffer[start:end], samples)]


def compose(only=None):
    """Mixagem completa, ou só uma parte (only = "piano", "baixo", "vibrafone" ou "percussao") para conferir o equilíbrio."""
    play = lambda part: only is None or only == part
    bars = len(FORM) * len(CHORUSES)
    loop = int(round(bars * BAR * RATE))
    buffer = [0.0] * (loop + int(TAIL * RATE))
    noise = Noise(7)
    swish = [noise.burst(0.42, 0.04, 0.16, 5200, 1400) for _ in range(4)]
    shaker = [noise.burst(0.09, 0.006, 0.03, 9000, 4500) for _ in range(4)]
    rim = rim_click(noise)
    solo_rng = random.Random(21)
    solo_note = 72
    for chorus, kind in enumerate(CHORUSES):
        for index, chords in enumerate(FORM):
            bar = chorus * len(FORM) + index
            t0 = bar * BAR
            # Piano: batida de bossa sobre o acorde da vez (o segundo acorde ocupa a metade de trás).
            for eighth, beats in COMP_EIGHTHS:
                if (eighth >= 8) != (bar % 2 == 1):
                    continue
                at = (eighth % 8) * 0.5
                chord = chords[0] if at < 2 or len(chords) == 1 else chords[1]
                comp_gain = PIANO_GAIN * (0.7 if kind == "solo" else 1.0)  # no solo, o acompanhamento recua
                for note in VOICINGS[chord] if play("piano") else []:
                    add(buffer, t0 + at * BEAT, electric_piano(midi(note), beats), comp_gain)
            # Contrabaixo: fundamental, quinta antecipada, quinta, e a nota que leva ao próximo compasso.
            pattern = [(0.0, 1.5, "root"), (1.5, 0.5, "fifth"), (2.0, 1.5, "fifth"), (3.5, 0.5, "root")]
            for at, beats, which in pattern if play("baixo") else []:
                chord = chords[0] if at < 2 or len(chords) == 1 else chords[1]
                note = ROOTS[chord] if which == "root" else FIFTHS[chord]
                add(buffer, t0 + at * BEAT, bass(midi(note), beats), BASS_GAIN)
            # Vibrafone: a melodia; na última volta, a primeira metade sobe uma oitava.
            if kind != "solo":
                for name, at, beats in MELODY[index] if play("vibrafone") else []:
                    m = midi(name) + (12 if kind == "melodia_alta" and index < 8 else 0)
                    add(buffer, t0 + at * BEAT, vibraphone(m, beats), VIBES_GAIN)
            # Solo do piano: escolhe notas boas do acorde, perto da anterior (passos pequenos soam cantados).
            elif play("piano"):
                rhythm = SOLO_RHYTHMS[solo_rng.randrange(len(SOLO_RHYTHMS))] if index != 15 else [(0, 3)]
                for at, beats in rhythm:
                    chord = chords[0] if at < 2 or len(chords) == 1 else chords[1]
                    options = [m for m in range(SOLO_LOW, SOLO_HIGH + 1) if m % 12 in SCALES[chord] and abs(m - solo_note) <= 5]
                    options = options or [m for m in range(SOLO_LOW, SOLO_HIGH + 1) if m % 12 in SCALES[chord]]
                    weights = [6.0 / (1 + abs(m - solo_note)) for m in options]
                    solo_note = solo_rng.choices(options, weights)[0]
                    add(buffer, t0 + at * BEAT, electric_piano(solo_note, beats), SOLO_GAIN)
            # Vassourinha nos tempos 2 e 4, caxixi nas colcheias, aro na clave.
            if not play("percussao"):
                continue
            for beat in (1, 3):
                add(buffer, t0 + beat * BEAT, swish[(bar + beat) % 4], SWISH_GAIN)
            for eighth in range(8):
                add(buffer, t0 + eighth * 0.5 * BEAT, shaker[eighth % 4], SHAKER_GAIN if eighth % 2 else SHAKER_GAIN * 0.6)
            for eighth in RIM_EIGHTHS:
                if (eighth >= 8) == (bar % 2 == 1):
                    add(buffer, t0 + (eighth % 8) * 0.5 * BEAT, rim, RIM_GAIN)
    # O que soa depois do fim volta para o começo: a faixa emenda sem corte.
    dry = buffer[:loop]
    for i, value in enumerate(buffer[loop:]):
        dry[i] += value
    return dry


def low_pass(samples, cutoff):
    a = math.exp(-2 * math.pi * cutoff / RATE)
    out = []
    y = 0.0
    for x in samples:
        y = (1 - a) * x + a * y
        out.append(y)
    return out


def reverb(samples, wet=0.22):
    """Reverberação de salão (Schroeder: 4 pentes em paralelo e 2 passa-tudo), sobre a faixa tocada
    duas vezes; fica a segunda, que já traz o eco da volta anterior e emenda certinho no loop."""
    doubled = samples + samples
    combs = [(810, 0.80), (862, 0.79), (927, 0.78), (984, 0.77)]
    acc = [0.0] * len(doubled)
    for delay, feedback in combs:
        line = [0.0] * delay
        damp = 0.0
        pos = 0
        for i, x in enumerate(doubled):
            out = line[pos]
            damp = out * 0.7 + damp * 0.3
            line[pos] = x + damp * feedback
            pos = (pos + 1) % delay
            acc[i] += out
    for delay in (403, 320):
        line = [0.0] * delay
        pos = 0
        for i, x in enumerate(acc):
            buffered = line[pos]
            out = -x + buffered
            line[pos] = x + buffered * 0.5
            pos = (pos + 1) % delay
            acc[i] = out
    n = len(samples)
    return [samples[i] * (1 - wet) + acc[n + i] * wet * 0.25 for i in range(n)]


def write_wav(path, samples):
    peak = max(abs(s) for s in samples) or 1.0
    gain = 0.85 / peak
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * gain)) * 32767)) for s in samples))


if __name__ == "__main__":
    mix = compose()
    mix = low_pass(mix, 9000)
    mix = reverb(mix)
    write_wav(OUT, mix)
    print(f"{len(mix) / RATE:.1f} s em {OUT}")
