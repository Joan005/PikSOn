#!/usr/bin/env python3
import os
import subprocess
import tempfile
import time
import numpy as np
import scipy.io.wavfile as wav
import whisper

WAKE_WORD = "hola"
CHUNK_SECS = 2
SILENCE_THRESHOLD = 300
SILENCE_SECS = 0.6

def notify(msg, duration=3000):
    env = os.environ.copy()
    env["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path=/run/user/{os.getuid()}/bus"
    subprocess.run(["notify-send", msg, "-t", str(duration)], env=env, stderr=subprocess.DEVNULL)

def record_ffmpeg(secs):
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        path = f.name
    subprocess.run([
        "ffmpeg", "-f", "pulse", "-i", "default",
        "-ar", "16000", "-ac", "1", "-t", str(secs),
        path, "-y"
    ], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
    try:
        _, data = wav.read(path)
        os.unlink(path)
        return data.astype(np.float32)
    except Exception:
        try: os.unlink(path)
        except: pass
        return np.zeros(int(secs * 16000), dtype=np.float32)

def record_until_silence():
    chunks = []
    silent = 0
    needed = int(SILENCE_SECS / 0.5)
    while True:
        chunk = record_ffmpeg(0.3)
        chunks.append(chunk)
        rms = np.sqrt(np.mean(chunk ** 2))
        if rms < SILENCE_THRESHOLD:
            silent += 1
            if silent >= needed:
                break
        else:
            silent = 0
        if sum(len(c) for c in chunks) > 16000 * 30:
            break
    return np.concatenate(chunks)

def transcribe(audio, model):
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        wav.write(f.name, 16000, audio.astype(np.int16))
        path = f.name
    result = model.transcribe(path, language="es", fp16=False)
    os.unlink(path)
    return result["text"].strip()

print("Cargando modelos Whisper...", flush=True)
tiny  = whisper.load_model("tiny")
small = whisper.load_model("small")
print(f"Escuchando '{WAKE_WORD}'...", flush=True)
notify(f"Bomboclat activo — di '{WAKE_WORD}' para hablar")

while True:
    audio = record_ffmpeg(CHUNK_SECS)
    text = transcribe(audio, tiny).lower()
    if WAKE_WORD.lower() in text:
        notify("Escuchando...", 8000)
        audio = record_until_silence()
        result = transcribe(audio, small)
        if result:
            subprocess.run(["wtype", result])
            notify(f"✓ {result[:60]}", 4000)
