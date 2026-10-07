"""Synthesize every Oink sound effect from scratch → assets/audio/*.mp3.

Contract: deterministic (fixed seeds), no network, no third-party samples, so the
audio is ours to ship. Needs numpy + scipy + ffmpeg on PATH.

    python tools/audio/synth.py            # writes assets/audio/*.mp3
    python tools/audio/synth.py --wav      # also keeps the .wav sources (for listening)

Design notes
- The piglet voice is a glottal pulse train (rich harmonics) pushed through three
  resonant band-passes placed at "nasal" formants, plus a little breath noise and a
  fast amplitude flutter that gives the gritty pig "grunt" texture. Pitch is a
  smooth contour per sound (rise-fall for a happy oink, rise for a question...).
- Everything is normalised to the same peak, then each file gets a short fade so
  nothing clicks when it is cut off.
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
import wave

import numpy as np
from scipy import signal

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "audio")


# ----------------------------------------------------------------- primitives
def t_axis(dur: float) -> np.ndarray:
    return np.arange(int(dur * SR)) / SR


def contour(points: list[tuple[float, float]], dur: float) -> np.ndarray:
    """Piecewise-smooth pitch/amp curve through (time_fraction, value) points."""
    t = np.linspace(0, 1, int(dur * SR))
    xs = np.array([p[0] for p in points])
    ys = np.array([p[1] for p in points])
    y = np.interp(t, xs, ys)
    # smooth corners with a short moving average (~8 ms)
    k = max(1, int(0.008 * SR))
    return np.convolve(y, np.ones(k) / k, mode="same") if len(y) > k else y


def env(dur: float, attack=0.01, release=0.08, sustain_shape=1.0) -> np.ndarray:
    n = int(dur * SR)
    e = np.ones(n)
    a = min(n, max(1, int(attack * SR)))
    r = min(n, max(1, int(release * SR)))
    e[:a] = np.linspace(0, 1, a) ** 0.6
    e[n - r:] *= np.linspace(1, 0, r) ** 1.4
    if sustain_shape != 1.0:
        e *= np.linspace(1, sustain_shape, n)
    return e


def glottal(f0: np.ndarray, rng: np.random.Generator, jitter=0.012) -> np.ndarray:
    """Band-limited-ish pulse train following f0 (Hz per sample)."""
    f = f0 * (1 + jitter * rng.standard_normal(len(f0)).cumsum() / np.sqrt(len(f0) + 1) * 0.0 + jitter * np.sin(np.arange(len(f0)) / SR * 2 * np.pi * 5.3))
    phase = np.cumsum(f / SR)
    frac = phase % 1.0
    # Rosenberg-like pulse: smooth open phase, sharp close → strong harmonics
    open_q = 0.55
    p = np.where(frac < open_q, 0.5 * (1 - np.cos(np.pi * frac / open_q)), np.cos(np.pi * (frac - open_q) / (2 * (1 - open_q))))
    d = np.diff(p, prepend=p[0])  # derivative ≈ glottal flow derivative
    return d / (np.max(np.abs(d)) + 1e-9)


def bandpass(x: np.ndarray, lo: float, hi: float, order=2) -> np.ndarray:
    sos = signal.butter(order, [lo, hi], btype="band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lowpass(x: np.ndarray, hz: float, order=2) -> np.ndarray:
    sos = signal.butter(order, hz, btype="low", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def highpass(x: np.ndarray, hz: float, order=2) -> np.ndarray:
    sos = signal.butter(order, hz, btype="high", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def formants(src: np.ndarray, fmts: list[tuple[float, float, float]]) -> np.ndarray:
    """Sum of band-passes (centre, bandwidth, gain)."""
    y = np.zeros_like(src)
    for c, bw, g in fmts:
        y += g * bandpass(src, max(40, c - bw / 2), min(SR / 2 - 100, c + bw / 2))
    return y


def piggy_voice(dur: float, pitch: list[tuple[float, float]], seed: int, *, grit=0.35, breath=0.08,
                nasal=1.0, amp: list[tuple[float, float]] | None = None, flutter_hz=38.0) -> np.ndarray:
    rng = np.random.default_rng(seed)
    f0 = contour(pitch, dur)
    src = glottal(f0, rng)
    # Nasal piglet formants: a strong low-mid "nn" + bright squeak
    voiced = formants(src, [(650 * nasal, 420, 1.0), (1450 * nasal, 600, 0.75), (2900 * nasal, 900, 0.35), (260, 160, 0.5)])
    t = t_axis(dur)[: len(voiced)]
    # Grit: amplitude flutter gives the grunt texture
    flutter = 1 - grit * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * flutter_hz * t))) * (0.6 + 0.4 * rng.random(len(t)))
    noise = bandpass(rng.standard_normal(len(t)), 900, 5000) * breath
    a = contour(amp, dur)[: len(t)] if amp else np.ones(len(t))
    y = (voiced * flutter + noise) * a * env(dur, 0.015, min(0.09, dur * 0.35))[: len(t)]
    return y


def bell(freq: float, dur: float, seed=0, bright=1.0) -> np.ndarray:
    t = t_axis(dur)
    partials = [(1.0, 1.0), (2.0, 0.45 * bright), (2.76, 0.25 * bright), (5.4, 0.12 * bright), (8.93, 0.05 * bright)]
    y = sum(g * np.sin(2 * np.pi * freq * m * t) * np.exp(-t * (3.0 + 2.2 * m)) for m, g in partials)
    return y * env(dur, 0.002, 0.05)


def tone_sweep(f_from: float, f_to: float, dur: float, decay=8.0, wave_shape="sine") -> np.ndarray:
    t = t_axis(dur)
    f = np.geomspace(f_from, f_to, len(t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = np.sin(ph) if wave_shape == "sine" else signal.sawtooth(ph, 0.5)
    return y * np.exp(-t * decay) * env(dur, 0.003, 0.02)


def place(total: float, parts: list[tuple[float, np.ndarray]]) -> np.ndarray:
    n = int(total * SR)
    out = np.zeros(n)
    for start, x in parts:
        s = int(start * SR)
        e = min(n, s + len(x))
        if s < n:
            out[s:e] += x[: e - s]
    return out


def finish(y: np.ndarray, peak=0.89) -> np.ndarray:
    y = y - np.mean(y)
    m = np.max(np.abs(y)) + 1e-9
    y = y / m * peak
    f = min(len(y), int(0.006 * SR))
    y[:f] *= np.linspace(0, 1, f)
    y[-f:] *= np.linspace(1, 0, f)
    return y


# ------------------------------------------------------------------- sounds
def oink(i: int) -> np.ndarray:
    specs = {
        1: dict(dur=0.42, pitch=[(0, 520), (0.25, 780), (0.65, 700), (1, 470)]),                 # happy
        2: dict(dur=0.34, pitch=[(0, 600), (0.35, 860), (1, 620)], grit=0.45),                     # short, bright
        3: dict(dur=0.48, pitch=[(0, 480), (0.5, 560), (0.85, 820), (1, 900)], grit=0.3),         # question ↑
        4: dict(dur=0.40, pitch=[(0, 700), (0.2, 900), (1, 560)], nasal=1.08),                     # squeaky
        5: dict(dur=0.46, pitch=[(0, 430), (0.3, 640), (1, 420)], grit=0.5, flutter_hz=32),        # proud, gruntier
    }
    if i == 6:  # double "oink-oink"
        a = piggy_voice(0.24, [(0, 560), (0.4, 820), (1, 600)], seed=60)
        b = piggy_voice(0.28, [(0, 600), (0.4, 880), (1, 560)], seed=61)
        return finish(place(0.62, [(0, a), (0.30, b)]))
    s = specs[i]
    return finish(piggy_voice(s["dur"], s["pitch"], seed=10 + i, grit=s.get("grit", 0.35),
                              nasal=s.get("nasal", 1.0), flutter_hz=s.get("flutter_hz", 38.0)))


def snort(i: int) -> np.ndarray:
    rng = np.random.default_rng(100 + i)
    dur = 0.36 if i == 1 else 0.5
    t = t_axis(dur)
    n = bandpass(rng.standard_normal(len(t)), 350, 1700, order=3)
    flutter = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * (26 + 6 * i) * t))
    a = contour([(0, 0), (0.15, 1), (0.5, 0.7), (1, 0)], dur)
    y = n * flutter * a
    if i == 2:  # two quick sniffs
        y = place(dur, [(0, y[: int(0.18 * SR)] * 0.8), (0.22, y[: int(0.22 * SR)])])
    voice = piggy_voice(dur, [(0, 300), (1, 260)], seed=120 + i, grit=0.7, flutter_hz=27) * 0.35
    return finish(y + voice[: len(y)])


def giggle(i: int) -> np.ndarray:
    rng = np.random.default_rng(200 + i)
    count = 6 if i == 1 else 8
    parts, t0 = [], 0.0
    base = 1050 if i == 1 else 980
    for k in range(count):
        p = base * (1 - 0.045 * k) * (1 + 0.04 * rng.standard_normal())
        d = 0.075 + 0.02 * rng.random()
        parts.append((t0, piggy_voice(d, [(0, p * 0.9), (0.4, p * 1.15), (1, p)], seed=210 + k + 10 * i, grit=0.2, breath=0.12)))
        t0 += d + 0.035 + 0.02 * rng.random()
    return finish(place(t0 + 0.05, parts))


def squeal_happy() -> np.ndarray:
    dur = 0.85
    t = t_axis(dur)
    base = contour([(0, 900), (0.3, 1450), (0.75, 1300), (1, 1100)], dur)
    vib = 1 + 0.03 * np.sin(2 * np.pi * 8.5 * t)
    return finish(piggy_voice(dur, [(x, y) for x, y in zip(np.linspace(0, 1, 50), (base * vib)[:: max(1, len(t) // 50)][:50])],
                              seed=300, grit=0.15, nasal=1.12, breath=0.1))


def whimper() -> np.ndarray:
    dur = 0.75
    return finish(piggy_voice(dur, [(0, 760), (0.3, 700), (0.6, 560), (1, 440)], seed=310, grit=0.1, breath=0.18,
                              amp=[(0, 0.6), (0.3, 1), (1, 0.5)]) * 0.8, peak=0.7)


def yawn() -> np.ndarray:
    dur = 1.15
    rng = np.random.default_rng(320)
    v = piggy_voice(dur, [(0, 620), (0.25, 680), (0.7, 420), (1, 330)], seed=321, grit=0.12, breath=0.3,
                    amp=[(0, 0.4), (0.25, 1), (0.8, 0.8), (1, 0)])
    air = lowpass(rng.standard_normal(len(v)), 1800) * contour([(0, 0), (0.6, 0.2), (1, 0.4)], dur)[: len(v)] * 0.3
    return finish(v + air, peak=0.8)


def snore() -> np.ndarray:
    rng = np.random.default_rng(330)
    tin = t_axis(1.25)
    inhale = lowpass(rng.standard_normal(len(tin)), 700, order=3)
    inhale *= (0.55 + 0.45 * np.sign(np.sin(2 * np.pi * 24 * tin))) * contour([(0, 0), (0.4, 1), (1, 0)], 1.25)
    out = piggy_voice(0.9, [(0, 330), (1, 260)], seed=331, grit=0.55, breath=0.4, flutter_hz=22,
                      amp=[(0, 0), (0.3, 0.6), (1, 0)]) * 0.45
    whistle = tone_sweep(900, 700, 0.9, decay=2.5) * 0.08
    return finish(place(2.8, [(0.0, inhale * 0.9), (1.45, out + whistle[: len(out)])]), peak=0.6)


def munch(i: int) -> np.ndarray:
    rng = np.random.default_rng(400 + i)
    parts, t0 = [], 0.0
    for k in range(3 + i % 2):
        d = 0.09 + 0.04 * rng.random()
        n = highpass(rng.standard_normal(int(d * SR)), 1200)
        n = bandpass(n, 1500, 7500) * np.exp(-t_axis(d) * (28 + 10 * rng.random()))
        thump = tone_sweep(180, 90, d, decay=30) * 0.6
        parts.append((t0, n + thump))
        t0 += d + 0.06 + 0.05 * rng.random()
    return finish(place(t0 + 0.05, parts), peak=0.85)


def gulp() -> np.ndarray:
    return finish(place(0.32, [(0, tone_sweep(520, 140, 0.32, decay=9)), (0, 0.25 * tone_sweep(900, 300, 0.12, decay=30))]))


def bubbles() -> np.ndarray:
    rng = np.random.default_rng(500)
    parts = []
    for _ in range(14):
        f = 700 + 1600 * rng.random()
        parts.append((0.85 * rng.random(), tone_sweep(f, f * 1.9, 0.07, decay=40) * (0.4 + 0.6 * rng.random())))
    return finish(place(1.0, parts), peak=0.75)


def scrub() -> np.ndarray:
    rng = np.random.default_rng(510)
    dur = 0.8
    t = t_axis(dur)
    n = bandpass(rng.standard_normal(len(t)), 600, 4000)
    am = 0.5 + 0.5 * np.sin(2 * np.pi * 7 * t) ** 2
    pops = place(dur, [(0.8 * rng.random(), tone_sweep(1200, 2400, 0.05, decay=60) * 0.5) for _ in range(5)])
    return finish(n * am * env(dur, 0.05, 0.15) * 0.6 + pops, peak=0.6)


def shower() -> np.ndarray:
    rng = np.random.default_rng(520)
    dur = 1.5
    t = t_axis(dur)
    hiss = bandpass(rng.standard_normal(len(t)), 2500, 11000) * contour([(0, 0), (0.15, 1), (0.8, 0.9), (1, 0)], dur)
    drops = place(dur, [(1.4 * rng.random(), tone_sweep(1400 + 900 * rng.random(), 600, 0.04, decay=80) * 0.6) for _ in range(28)])
    return finish(hiss * 0.5 + drops, peak=0.6)


def sparkle() -> np.ndarray:
    notes = [1568, 1976, 2349, 3136]
    return finish(place(0.9, [(i * 0.07, bell(f, 0.6, bright=1.3) * (0.9 - 0.1 * i)) for i, f in enumerate(notes)]), peak=0.7)


def pop() -> np.ndarray:
    return finish(tone_sweep(500, 1300, 0.09, decay=45), peak=0.7)


def tap() -> np.ndarray:
    rng = np.random.default_rng(600)
    d = 0.06
    click = bandpass(rng.standard_normal(int(d * SR)), 1200, 4500) * np.exp(-t_axis(d) * 90)
    body = np.sin(2 * np.pi * 1650 * t_axis(d)) * np.exp(-t_axis(d) * 70) * 0.6
    return finish(click + body, peak=0.55)


def acorn() -> np.ndarray:
    return finish(place(0.45, [(0, bell(1976, 0.3)), (0.07, bell(2637, 0.38))]), peak=0.7)


def catch() -> np.ndarray:
    return finish(place(0.3, [(0, tone_sweep(880, 900, 0.08, decay=20)), (0.06, tone_sweep(1175, 1200, 0.08, decay=20)),
                              (0.12, tone_sweep(1568, 1600, 0.14, decay=16))]), peak=0.65)


def bonk() -> np.ndarray:
    rng = np.random.default_rng(700)
    d = 0.4
    thud = tone_sweep(320, 110, d, decay=10)
    n = lowpass(rng.standard_normal(int(d * SR)), 1200) * np.exp(-t_axis(d) * 30) * 0.4
    return finish(thud + n, peak=0.75)


def levelup() -> np.ndarray:
    seq = [1047, 1319, 1568, 2093]
    parts = [(i * 0.12, bell(f, 0.6, bright=1.1)) for i, f in enumerate(seq)]
    parts += [(0.55, (bell(1047, 1.2) + bell(1319, 1.2) + bell(1568, 1.2) + bell(2093, 1.2, bright=1.4)) * 0.45)]
    return finish(place(1.8, parts), peak=0.75)


def gift() -> np.ndarray:
    gl = [784, 988, 1175, 1397, 1568, 1760, 2093, 2349]
    parts = [(i * 0.045, bell(f, 0.5, bright=0.8) * 0.7) for i, f in enumerate(gl)]
    parts.append((0.45, bell(3136, 0.7, bright=1.4)))
    return finish(place(1.2, parts), peak=0.7)


def wake() -> np.ndarray:
    return finish(place(0.85, [(0, bell(784, 0.6, bright=0.6)), (0.22, bell(1047, 0.6, bright=0.6))]), peak=0.6)


SOUNDS = {
    **{f"oink_{i}": (lambda i=i: oink(i)) for i in range(1, 7)},
    "snort_1": lambda: snort(1), "snort_2": lambda: snort(2),
    "giggle_1": lambda: giggle(1), "giggle_2": lambda: giggle(2),
    "squeal_happy": squeal_happy, "whimper": whimper, "yawn": yawn, "snore": snore,
    "munch_1": lambda: munch(1), "munch_2": lambda: munch(2), "munch_3": lambda: munch(3), "gulp": gulp,
    "bubbles": bubbles, "scrub": scrub, "shower": shower, "sparkle": sparkle,
    "pop": pop, "tap": tap, "acorn": acorn, "catch": catch, "bonk": bonk,
    "levelup": levelup, "gift": gift, "wake": wake,
}


def write_wav(path: str, y: np.ndarray) -> None:
    pcm = (np.clip(y, -1, 1) * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--wav", action="store_true", help="keep .wav sources next to the mp3s")
    ap.add_argument("only", nargs="*", help="subset of sound names")
    a = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    names = a.only or list(SOUNDS)
    for name in names:
        y = SOUNDS[name]()
        wav = os.path.join(OUT, f"{name}.wav")
        mp3 = os.path.join(OUT, f"{name}.mp3")
        write_wav(wav, y)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-ac", "1", "-ar", "44100",
                        "-codec:a", "libmp3lame", "-b:a", "96k", mp3], check=True)
        if not a.wav:
            os.remove(wav)
        print(f"{name:14s} {len(y) / SR:5.2f}s  {os.path.getsize(mp3) // 1024:4d} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
