import torch

# --- Audio ---
SAMPLE_RATE = 24000
MP3_BITRATE = "320k"
MP3_BITRATE_STREAM = "256k"

# --- Server ---
HOST = "0.0.0.0"
PORT = 8880

# --- Device ---
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# --- Text chunking ---
CHUNK_TARGET_MIN_CHARS = 80
CHUNK_TARGET_MAX_CHARS = 250
CHUNK_ABSOLUTE_MAX_CHARS = 450

# --- Crossfade and silence ---
CROSSFADE_MS = 20
SILENCE_BETWEEN_CHUNKS_MS = 350

# --- Kokoro / Edge TTS ---
DEFAULT_LANG = "pt-br"
DEFAULT_LANG_CODE = "p"
DEFAULT_VOICE = "pf_dora"

LANGUAGES = {
    "en-us": {
        "id": "en-us",
        "name": "English",
        "label": "American English",
        "kokoro_code": "a",
        "supported": True,
        "sample_text": "Hello. This is a multilingual Kokoro voice synthesis test.",
    },
    "en-gb": {
        "id": "en-gb",
        "name": "English",
        "label": "British English",
        "kokoro_code": "b",
        "supported": True,
        "sample_text": "Hello. This is a British English Kokoro voice synthesis test.",
    },
    "de-de": {
        "id": "de-de",
        "name": "Deutsch",
        "label": "German",
        "kokoro_code": None,
        "supported": True,
        "sample_text": "Hallo. Dies ist ein deutscher Sprachsynthese-Test.",
    },
    "fr-fr": {
        "id": "fr-fr",
        "name": "Francais",
        "label": "French",
        "kokoro_code": "f",
        "supported": True,
        "sample_text": "Bonjour. Ceci est un test de synthese vocale multilingue avec Kokoro.",
    },
    "ja-jp": {
        "id": "ja-jp",
        "name": "Nihongo",
        "label": "Japanese",
        "kokoro_code": "j",
        "supported": True,
        "sample_text": "こんにちは。これはKokoroの多言語音声合成テストです。",
    },
    "zh-cn": {
        "id": "zh-cn",
        "name": "Zhongwen",
        "label": "Chinese",
        "kokoro_code": "z",
        "supported": True,
        "sample_text": "你好。这是一个 Kokoro 多语言语音合成测试。",
    },
    "es-es": {
        "id": "es-es",
        "name": "Espanol",
        "label": "Spanish",
        "kokoro_code": "e",
        "supported": True,
        "sample_text": "Hola. Esta es una prueba de sintesis de voz multilingue con Kokoro.",
    },
    "hi-in": {
        "id": "hi-in",
        "name": "Hindi",
        "label": "Hindi",
        "kokoro_code": "h",
        "supported": True,
        "sample_text": "नमस्ते। यह Kokoro की बहुभाषी वॉइस सिंथेसिस जांच है।",
    },
    "it-it": {
        "id": "it-it",
        "name": "Italiano",
        "label": "Italian",
        "kokoro_code": "i",
        "supported": True,
        "sample_text": "Ciao. Questo e un test di sintesi vocale multilingue con Kokoro.",
    },
    "pt-br": {
        "id": "pt-br",
        "name": "Portugues",
        "label": "Portuguese",
        "kokoro_code": "p",
        "supported": True,
        "sample_text": "Hello. This is a multilingual voice synthesis test with Kokoro.",
    },
}


def kokoro_voice(voice_id: str, name: str, gender: str, lang: str, lang_code: str, description: str) -> dict:
    return {
        "id": voice_id,
        "name": name,
        "gender": gender,
        "lang": lang,
        "lang_code": lang_code,
        "engine": "kokoro",
        "source": f"models/kokoro_voices/voices/{voice_id}.pt",
        "description": description,
    }


def edge_voice(
    voice_id: str,
    name: str,
    gender: str,
    lang: str,
    source: str,
    description: str,
    default_speed: float | None = None,
    default_pitch: int | None = None,
) -> dict:
    voice = {
        "id": voice_id,
        "name": name,
        "gender": gender,
        "lang": lang,
        "lang_code": None,
        "engine": "edge",
        "source": source,
        "description": description,
    }
    if default_speed is not None:
        voice["default_speed"] = default_speed
    if default_pitch is not None:
        voice["default_pitch"] = default_pitch
    return voice


VOICES = {
    "de_f_katja": edge_voice(
        "de_f_katja", "Katja", "female", "de-de", "de-DE-KatjaNeural", "German female voice from Germany"
    ),
    "de_m_conrad": edge_voice(
        "de_m_conrad", "Conrad", "male", "de-de", "de-DE-ConradNeural", "German male voice from Germany"
    ),
    "de_f_leni": edge_voice(
        "de_f_leni", "Leni", "female", "de-de", "de-CH-LeniNeural", "German female voice from Switzerland"
    ),
    "de_m_jonas": edge_voice(
        "de_m_jonas", "Jonas", "male", "de-de", "de-AT-JonasNeural", "German male voice from Austria"
    ),
    "pt_f_menina": edge_voice(
        "pt_f_menina",
        "Menina",
        "female",
        "pt-br",
        "pt-BR-ThalitaMultilingualNeural",
        "Brazilian child female voice with higher pitch",
        default_speed=1.08,
        default_pitch=46,
    ),
    "pt_m_menino": edge_voice(
        "pt_m_menino",
        "Menino",
        "male",
        "pt-br",
        "pt-BR-AntonioNeural",
        "Brazilian child male voice with younger tone",
        default_speed=1.05,
        default_pitch=28,
    ),
    "af_heart": kokoro_voice("af_heart", "Heart", "female", "en-us", "a", "American English female voice"),
    "af_alloy": kokoro_voice("af_alloy", "Alloy", "female", "en-us", "a", "American English female voice"),
    "af_aoede": kokoro_voice("af_aoede", "Aoede", "female", "en-us", "a", "American English female voice"),
    "af_bella": kokoro_voice("af_bella", "Bella", "female", "en-us", "a", "American English female voice"),
    "af_jessica": kokoro_voice("af_jessica", "Jessica", "female", "en-us", "a", "American English female voice"),
    "af_kore": kokoro_voice("af_kore", "Kore", "female", "en-us", "a", "American English female voice"),
    "af_nicole": kokoro_voice("af_nicole", "Nicole", "female", "en-us", "a", "American English female voice"),
    "af_nova": kokoro_voice("af_nova", "Nova", "female", "en-us", "a", "American English female voice"),
    "af_river": kokoro_voice("af_river", "River", "female", "en-us", "a", "American English female voice"),
    "af_sarah": kokoro_voice("af_sarah", "Sarah", "female", "en-us", "a", "American English female voice"),
    "af_sky": kokoro_voice("af_sky", "Sky", "female", "en-us", "a", "American English female voice"),
    "am_adam": kokoro_voice("am_adam", "Adam", "male", "en-us", "a", "American English male voice"),
    "am_echo": kokoro_voice("am_echo", "Echo", "male", "en-us", "a", "American English male voice"),
    "am_eric": kokoro_voice("am_eric", "Eric", "male", "en-us", "a", "American English male voice"),
    "am_fenrir": kokoro_voice("am_fenrir", "Fenrir", "male", "en-us", "a", "American English male voice"),
    "am_liam": kokoro_voice("am_liam", "Liam", "male", "en-us", "a", "American English male voice"),
    "am_michael": kokoro_voice("am_michael", "Michael", "male", "en-us", "a", "American English male voice"),
    "am_onyx": kokoro_voice("am_onyx", "Onyx", "male", "en-us", "a", "American English male voice"),
    "am_puck": kokoro_voice("am_puck", "Puck", "male", "en-us", "a", "American English male voice"),
    "am_santa": kokoro_voice("am_santa", "Santa", "male", "en-us", "a", "American English male voice"),
    "bf_alice": kokoro_voice("bf_alice", "Alice", "female", "en-gb", "b", "British English female voice"),
    "bf_emma": kokoro_voice("bf_emma", "Emma", "female", "en-gb", "b", "British English female voice"),
    "bf_isabella": kokoro_voice("bf_isabella", "Isabella", "female", "en-gb", "b", "British English female voice"),
    "bf_lily": kokoro_voice("bf_lily", "Lily", "female", "en-gb", "b", "British English female voice"),
    "bm_daniel": kokoro_voice("bm_daniel", "Daniel", "male", "en-gb", "b", "British English male voice"),
    "bm_fable": kokoro_voice("bm_fable", "Fable", "male", "en-gb", "b", "British English male voice"),
    "bm_george": kokoro_voice("bm_george", "George", "male", "en-gb", "b", "British English male voice"),
    "bm_lewis": kokoro_voice("bm_lewis", "Lewis", "male", "en-gb", "b", "British English male voice"),
    "ef_dora": kokoro_voice("ef_dora", "Dora", "female", "es-es", "e", "Spanish female voice"),
    "em_alex": kokoro_voice("em_alex", "Alex", "male", "es-es", "e", "Spanish male voice"),
    "em_santa": kokoro_voice("em_santa", "Santa", "male", "es-es", "e", "Spanish male voice"),
    "ff_siwis": kokoro_voice("ff_siwis", "Siwis", "female", "fr-fr", "f", "French female voice"),
    "hf_alpha": kokoro_voice("hf_alpha", "Alpha", "female", "hi-in", "h", "Hindi female voice"),
    "hf_beta": kokoro_voice("hf_beta", "Beta", "female", "hi-in", "h", "Hindi female voice"),
    "hm_omega": kokoro_voice("hm_omega", "Omega", "male", "hi-in", "h", "Hindi male voice"),
    "hm_psi": kokoro_voice("hm_psi", "Psi", "male", "hi-in", "h", "Hindi male voice"),
    "if_sara": kokoro_voice("if_sara", "Sara", "female", "it-it", "i", "Italian female voice"),
    "im_nicola": kokoro_voice("im_nicola", "Nicola", "male", "it-it", "i", "Italian male voice"),
    "jf_alpha": kokoro_voice("jf_alpha", "Alpha", "female", "ja-jp", "j", "Japanese female voice"),
    "jf_gongitsune": kokoro_voice("jf_gongitsune", "Gongitsune", "female", "ja-jp", "j", "Japanese female voice"),
    "jf_nezumi": kokoro_voice("jf_nezumi", "Nezumi", "female", "ja-jp", "j", "Japanese female voice"),
    "jf_tebukuro": kokoro_voice("jf_tebukuro", "Tebukuro", "female", "ja-jp", "j", "Japanese female voice"),
    "jm_kumo": kokoro_voice("jm_kumo", "Kumo", "male", "ja-jp", "j", "Japanese male voice"),
    "pf_dora": kokoro_voice("pf_dora", "Dora", "female", "pt-br", "p", "Brazilian Portuguese female voice"),
    "pm_alex": kokoro_voice("pm_alex", "Alex", "male", "pt-br", "p", "Brazilian Portuguese male voice"),
    "pm_santa": kokoro_voice("pm_santa", "Santa", "male", "pt-br", "p", "Brazilian Portuguese male voice"),
    "zf_xiaobei": kokoro_voice("zf_xiaobei", "Xiaobei", "female", "zh-cn", "z", "Mandarin Chinese female voice"),
    "zf_xiaoni": kokoro_voice("zf_xiaoni", "Xiaoni", "female", "zh-cn", "z", "Mandarin Chinese female voice"),
    "zf_xiaoxiao": kokoro_voice("zf_xiaoxiao", "Xiaoxiao", "female", "zh-cn", "z", "Mandarin Chinese female voice"),
    "zf_xiaoyi": kokoro_voice("zf_xiaoyi", "Xiaoyi", "female", "zh-cn", "z", "Mandarin Chinese female voice"),
    "zm_yunjian": kokoro_voice("zm_yunjian", "Yunjian", "male", "zh-cn", "z", "Mandarin Chinese male voice"),
    "zm_yunxi": kokoro_voice("zm_yunxi", "Yunxi", "male", "zh-cn", "z", "Mandarin Chinese male voice"),
    "zm_yunxia": kokoro_voice("zm_yunxia", "Yunxia", "male", "zh-cn", "z", "Mandarin Chinese male voice"),
    "zm_yunyang": kokoro_voice("zm_yunyang", "Yunyang", "male", "zh-cn", "z", "Mandarin Chinese male voice"),
}
