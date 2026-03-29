# Evo KokoroTTS

[![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue)](https://github.com/marksjr/EvoKokoroTTS)
[![API](https://img.shields.io/badge/api-FastAPI-05998b)](https://github.com/marksjr/EvoKokoroTTS)
[![Model](https://img.shields.io/badge/model-Kokoro--82M-black)](https://github.com/marksjr/EvoKokoroTTS)
[![Voices](https://img.shields.io/badge/voices-54%20Kokoro%20%2B%206%20Edge-6c8aff)](https://github.com/marksjr/EvoKokoroTTS)

Local **multilingual Text-to-Speech API** built with **Kokoro-82M** plus complementary **Edge TTS** voices.

Generate high-quality speech in MP3 or WAV, stream audio in real time, use a FastAPI REST API, or work directly from the built-in English web UI.

**Best for:** local multilingual TTS, bundled Kokoro voice coverage, simple Windows setup, and a ready-to-use browser interface.

---

## Highlights

- **54 official Kokoro voices included locally**
- **6 extra Edge TTS voices** for German and child-like Brazilian presets
- **10 language options in the catalog**
- **Automatic Kokoro / Edge routing** based on the selected voice
- **English web UI**
- **MP3 and WAV output**
- **Real-time MP3 streaming**
- **Automatic voice availability validation**
- **CUDA or CPU auto-detection**
- **Local bootstrap installer** via `install.bat`

Supported language codes:
`pt-br`, `en-us`, `en-gb`, `es-es`, `fr-fr`, `ja-jp`, `zh-cn`, `hi-in`, `it-it`, `de-de`

---

## Why This Repo

- **Bundled voice files**: all official Kokoro-82M v1.0 voices are already present in the repository
- **Practical Windows setup**: installer-first workflow with local runtime helpers
- **Two usage modes**: browser UI for direct use and REST API for integration
- **Safer voice handling**: unavailable voices are blocked before synthesis instead of failing late
- **Broader language reach**: Kokoro voices plus Edge-only fallback voices where useful

---

## Included Voice Coverage

This repository includes:

- **All 54 official Kokoro-82M v1.0 voice files** in `models/kokoro_voices/voices/`
- **6 Edge TTS voices** registered in the API catalog:
  - `de_f_katja`
  - `de_m_conrad`
  - `de_f_leni`
  - `de_m_jonas`
  - `pt_f_menina`
  - `pt_m_menino`

The API marks each voice as available or unavailable and rejects requests for missing local Kokoro voice files before synthesis starts.

---

## Installation

### Requirements

- **Windows 10/11** (64-bit)
- **espeak-ng** required for Kokoro synthesis

The installer already handles:

- **Python 3.11 Embedded**: bundled zip included in the repo, extracts automatically
- **espeak-ng**: bundled MSI installer opens interactively (just click "Next")
- **ffmpeg**: uses copy from `ffmpeg/` if present, or downloads automatically
- PyTorch CPU or CUDA build
- Python dependencies from `requirements.txt`

Supported `espeak-ng` setups:

- installed globally and available in `PATH`
- portable copy in `.\espeak-ng\`
- portable copy in `.\espeak-ng\command_line\`
- auto-extracted portable copy in `.\espeak-ng\eSpeak NG\`
- bundled MSI installer `espeak-ng-installer.msi` (included in the repo)

### Quick Start

```powershell
git clone https://github.com/marksjr/EvoKokoroTTS.git
cd EvoKokoroTTS
install.bat
start.bat
```

For non-technical Windows users:

1. Download the project as ZIP from GitHub and extract it.
2. Open the extracted folder.
3. Run `start.bat` — it will install everything automatically on the first run.
4. If `espeak-ng` is missing, the bundled installer will open — just click "Next" to install.

### Offline / VM Installation

The following components are already included in the repo and do **not** require internet:

| Component | Status |
|-----------|--------|
| **Python 3.11 Embedded** | Included (`installers/python.zip`, 11 MB) |
| **espeak-ng** | Included (`installers/espeak-ng-installer.msi`, 13 MB) |
| **Visual C++ Redistributable** | Included (`installers/vc_redist.x64.exe`, 25 MB) |
| **ffmpeg** | **Must be added manually** (too large for GitHub) |

For ffmpeg, download in advance on a machine with internet:

| Build | Download Link |
|-------|--------------|
| **FFmpeg Windows 64-bit (shared)** | [ffmpeg-master-latest-win64-gpl-shared.zip](https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip) |
| **FFmpeg Windows 64-bit (static)** | [ffmpeg-master-latest-win64-gpl.zip](https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip) |
| **All FFmpeg builds** | [github.com/BtbN/FFmpeg-Builds/releases](https://github.com/BtbN/FFmpeg-Builds/releases) |

Steps:

1. Extract `ffmpeg.exe` + `ffprobe.exe` from the FFmpeg zip into the `ffmpeg/` folder inside the project.
2. Copy the entire project folder to the target machine and run the installer.
3. Internet is still needed for PyTorch and Python packages (~200 MB on first install).

If someone starts `start.bat` before the installation is complete, the launcher now tries to repair the environment automatically by calling `install.bat`.

If a system Python is installed but incompatible, the installer now ignores it and switches to the bundled Python 3.11 runtime automatically.

After startup, open:

- Web UI: `http://localhost:8880`
- Swagger docs: `http://localhost:8880/docs`
- Extended docs: `http://localhost:8880/doc.html`

---

## Web Interface

The local UI includes:

- text input up to **10,000 characters**
- language and voice selection
- speed and pitch controls
- MP3 / WAV format toggle
- full generation and streaming actions
- live generation timer
- inline availability state for voices
- in-browser playback and download

Top-right status shows:

- **Online / Offline**
- **GPU (CUDA)** or **CPU**

---

## API

### Endpoints

| Method | Route | Description |
|--------|-------|-------------|
| `GET` | `/health` | API status, device, model state |
| `GET` | `/languages` | Available language catalog |
| `GET` | `/voices` | Full voice catalog with availability |
| `POST` | `/tts` | Full audio generation (`mp3` or `wav`) |
| `POST` | `/tts/stream` | Real-time MP3 streaming |

### `POST /tts`

```json
{
  "text": "Hello from Evo KokoroTTS.",
  "voice": "af_bella",
  "speed": 1.0,
  "pitch": 0,
  "format": "mp3"
}
```

### `POST /tts/stream`

```json
{
  "text": "This is a live streaming synthesis test.",
  "voice": "pm_alex",
  "speed": 1.0,
  "pitch": 0
}
```

Voice validation checks:

- voice exists in the catalog
- language is supported
- local Kokoro `.pt` file exists when required

---

## Example cURL Commands

```bash
# Health
curl http://localhost:8880/health

# Languages
curl http://localhost:8880/languages

# Voices
curl http://localhost:8880/voices

# Minimal MP3
curl -X POST http://localhost:8880/tts \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"Hello world.\"}" \
  --output audio.mp3

# Brazilian Portuguese Kokoro
curl -X POST http://localhost:8880/tts \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"Ola. Este e um teste em portugues.\",\"voice\":\"pf_dora\",\"format\":\"mp3\"}" \
  --output pt.mp3

# British English Kokoro
curl -X POST http://localhost:8880/tts \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"Hello. This is a British English test.\",\"voice\":\"bf_alice\",\"format\":\"mp3\"}" \
  --output en_gb.mp3

# Chinese Kokoro
curl -X POST http://localhost:8880/tts \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"Ni hao. Zhe shi yi ge zhong wen ce shi.\",\"voice\":\"zf_xiaoxiao\",\"format\":\"mp3\"}" \
  --output zh.mp3

# Edge voice with pitch
curl -X POST http://localhost:8880/tts \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"Testing Edge voice pitch.\",\"voice\":\"pt_f_menina\",\"speed\":1.08,\"pitch\":46}" \
  --output edge.mp3

# WAV
curl -X POST http://localhost:8880/tts \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"Uncompressed output.\",\"format\":\"wav\"}" \
  --output audio.wav

# Streaming
curl -X POST http://localhost:8880/tts/stream \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"Streaming test in real time.\"}" \
  --output stream.mp3
```

---

## Language and Voice Notes

- `en-us` covers the American English Kokoro voices
- `en-gb` covers the British English Kokoro voices
- `de-de` currently uses the extra Edge TTS voices
- `pt-br` includes both official Kokoro voices and two extra Edge child-like presets
- `zh-cn` requires the Chinese text-processing dependencies already listed in `requirements.txt`

Use `GET /voices` to inspect the full catalog returned by the running instance.

---

## Tested Voices

The following voices were tested successfully in this project after the recent update:

- `pf_dora` for Brazilian Portuguese
- `pm_alex` for Brazilian Portuguese
- `bf_alice` for British English
- `zf_xiaoxiao` for Chinese

Chinese voice support also required these runtime dependencies, now included in `requirements.txt`:

- `ordered-set`
- `pypinyin`
- `cn2an`
- `jieba`

---

## Dependencies

Current Python dependencies include:

- `fastapi`
- `uvicorn[standard]`
- `kokoro`
- `torch`
- `edge-tts`
- `soundfile`
- `numpy`
- `pydub`
- `ordered-set`
- `pypinyin`
- `cn2an`
- `jieba`

---

## Technical Specs

| Item | Value |
|------|-------|
| Model | Kokoro-82M |
| Kokoro sample rate | 24 kHz |
| MP3 bitrate (full) | 320 kbps |
| MP3 bitrate (streaming) | 256 kbps |
| WAV | 16-bit PCM mono |
| Port | `8880` |
| Device | CUDA if available, otherwise CPU |
| Max text length | 10,000 characters |
| Speed range | `0.5x` to `2.0x` |
| Concurrent Kokoro workers | 4 |

---

## Project Structure

```text
EvoKokoroTTS/
|-- install.bat
|-- start.bat
|-- start.py
|-- requirements.txt
|-- doc.html
|-- README.md
|-- installers/
|   |-- python.zip              (bundled Python 3.11)
|   |-- espeak-ng-installer.msi (bundled espeak-ng)
|   `-- vc_redist.x64.exe       (bundled Visual C++)
|-- ffmpeg/                  (add ffmpeg.exe here for offline installs)
|-- models/
|   `-- kokoro_voices/
|       `-- voices/
`-- app/
    |-- main.py
    |-- api/
    |   `-- routes.py
    |-- core/
    |   `-- config.py
    |-- engines/
    |   |-- edge_engine.py
    |   `-- kokoro_engine.py
    |-- models/
    |   `-- schemas.py
    |-- services/
    |   `-- tts_service.py
    |-- static/
    |   `-- index.html
    `-- utils/
        |-- audio.py
        `-- text.py
```

---

## License

MIT
