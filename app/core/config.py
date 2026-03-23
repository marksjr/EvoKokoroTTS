import torch

# --- Áudio ---
SAMPLE_RATE = 24000
MP3_BITRATE = "320k"
MP3_BITRATE_STREAM = "256k"

# --- Servidor ---
HOST = "0.0.0.0"
PORT = 8880

# --- Device ---
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# --- Chunking de texto ---
CHUNK_TARGET_MIN_CHARS = 80
CHUNK_TARGET_MAX_CHARS = 250
CHUNK_ABSOLUTE_MAX_CHARS = 450

# --- Crossfade e silêncio ---
CROSSFADE_MS = 50
SILENCE_BETWEEN_CHUNKS_MS = 80

# --- Kokoro pt-BR ---
LANG_CODE = "p"
DEFAULT_VOICE = "pf_dora"

VOICES = {
    "pf_dora": {
        "id": "pf_dora",
        "name": "Dora",
        "gender": "feminino",
        "lang": "pt-br",
        "description": "Voz feminina brasileira - Dora",
    },
    "pm_alex": {
        "id": "pm_alex",
        "name": "Alex",
        "gender": "masculino",
        "lang": "pt-br",
        "description": "Voz masculina brasileira - Alex",
    },
    "pm_santa": {
        "id": "pm_santa",
        "name": "Santa",
        "gender": "masculino",
        "lang": "pt-br",
        "description": "Voz masculina brasileira - Santa",
    },
}
