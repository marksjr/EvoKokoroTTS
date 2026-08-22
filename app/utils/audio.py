import io
import struct

import numpy as np
from pydub import AudioSegment

from app.core.config import CROSSFADE_MS, MP3_BITRATE, MP3_BITRATE_STREAM, SAMPLE_RATE, SILENCE_BETWEEN_CHUNKS_MS


def numpy_to_wav_bytes(audio: np.ndarray) -> bytes:
    """Converts a numpy array to WAV bytes."""
    buf = io.BytesIO()
    audio_int16 = np.clip(audio * 32767, -32768, 32767).astype(np.int16)
    num_samples = len(audio_int16)
    data_size = num_samples * 2

    buf.write(b"RIFF")
    buf.write(struct.pack("<I", 36 + data_size))
    buf.write(b"WAVE")
    buf.write(b"fmt ")
    buf.write(struct.pack("<I", 16))
    buf.write(struct.pack("<H", 1))
    buf.write(struct.pack("<H", 1))
    buf.write(struct.pack("<I", SAMPLE_RATE))
    buf.write(struct.pack("<I", SAMPLE_RATE * 2))
    buf.write(struct.pack("<H", 2))
    buf.write(struct.pack("<H", 16))
    buf.write(b"data")
    buf.write(struct.pack("<I", data_size))
    buf.write(audio_int16.tobytes())

    return buf.getvalue()


def normalize_audio(audio: np.ndarray, target_peak: float = 0.95) -> np.ndarray:
    """Normalizes audio for consistent volume."""
    peak = np.max(np.abs(audio))
    if peak > 0:
        audio = audio * (target_peak / peak)
    return audio


def crossfade_chunks(chunks: list[np.ndarray], crossfade_samples: int = None) -> np.ndarray:
    """Concatenates audio chunks with smooth crossfade."""
    if not chunks:
        return np.array([], dtype=np.float32)
    if len(chunks) == 1:
        return chunks[0]

    if crossfade_samples is None:
        crossfade_samples = int(SAMPLE_RATE * CROSSFADE_MS / 1000)

    silence_samples = int(SAMPLE_RATE * SILENCE_BETWEEN_CHUNKS_MS / 1000)
    total_len = sum(len(chunk) for chunk in chunks)
    total_len += silence_samples * (len(chunks) - 1)
    total_len -= crossfade_samples * (len(chunks) - 1)
    result = np.zeros(total_len, dtype=np.float32)

    pos = len(chunks[0])
    result[:pos] = chunks[0]

    for chunk in chunks[1:]:
        pos += silence_samples
        crossfade = min(crossfade_samples, pos, len(chunk))
        if crossfade > 10:
            fade_out = np.linspace(1.0, 0.0, crossfade, dtype=np.float32)
            fade_in = np.linspace(0.0, 1.0, crossfade, dtype=np.float32)
            result[pos - crossfade:pos] *= fade_out
            result[pos - crossfade:pos] += chunk[:crossfade] * fade_in
            result[pos:pos + len(chunk) - crossfade] = chunk[crossfade:]
            pos += len(chunk) - crossfade
        else:
            result[pos:pos + len(chunk)] = chunk
            pos += len(chunk)

    return result[:pos]


def trim_silence(audio: np.ndarray, threshold: float = 0.01, pad_samples: int = 3600) -> np.ndarray:
    """Removes excessive silence from the beginning and end of the audio."""
    mask = np.abs(audio) > threshold
    if not mask.any():
        return audio

    indices = np.where(mask)[0]
    start = max(0, indices[0] - pad_samples)
    end = min(len(audio), indices[-1] + pad_samples)
    return audio[start:end]


def numpy_to_mp3_bytes(audio: np.ndarray, bitrate: str = None) -> bytes:
    """Converts a numpy array to MP3 bytes."""
    if bitrate is None:
        bitrate = MP3_BITRATE

    wav_bytes = numpy_to_wav_bytes(audio)
    segment = AudioSegment.from_wav(io.BytesIO(wav_bytes))
    buf = io.BytesIO()
    segment.export(
        buf,
        format="mp3",
        bitrate=bitrate,
        parameters=["-q:a", "0"],
    )
    return buf.getvalue()


def numpy_to_mp3_chunk(audio: np.ndarray) -> bytes:
    """Converts a numpy audio chunk to MP3."""
    return numpy_to_mp3_bytes(audio, bitrate=MP3_BITRATE_STREAM)


def mp3_bytes_to_wav_bytes(audio_bytes: bytes) -> bytes:
    """Converts MP3 bytes to WAV bytes."""
    segment = AudioSegment.from_file(io.BytesIO(audio_bytes), format="mp3")
    buf = io.BytesIO()
    segment.export(buf, format="wav")
    return buf.getvalue()
