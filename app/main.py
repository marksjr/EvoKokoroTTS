import logging
import threading
import webbrowser
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from app.api.routes import router
from app.core.config import DEVICE, HOST, PORT
from app.services.tts_service import tts_service

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)

STATIC_DIR = Path(__file__).parent / "static"
ROOT_DIR = Path(__file__).parent.parent


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"Iniciando Evo KokoroTTS (device: {DEVICE})")
    tts_service.load_model()
    logger.info("Evo KokoroTTS pronta para receber requisicoes")
    # Abrir navegador automaticamente após modelo carregar
    threading.Thread(
        target=lambda: webbrowser.open(f"http://localhost:{PORT}"),
        daemon=True,
    ).start()
    yield
    logger.info("Encerrando Evo KokoroTTS")


app = FastAPI(
    title="Evo KokoroTTS",
    description=(
        "API local de Text-to-Speech multilíngue com Kokoro-82M e Edge TTS. "
        "Suporta catálogo de idiomas, vozes por engine, geração completa em MP3/WAV, "
        "streaming em MP3 e ajuste de pitch para vozes Edge, incluindo presets infantis."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)


@app.get("/", include_in_schema=False)
async def root():
    """Redireciona para a interface web."""
    return FileResponse(STATIC_DIR / "index.html")


@app.get("/doc.html", include_in_schema=False)
async def doc_page():
    """Serves the documentation page."""
    doc_file = STATIC_DIR / "doc.html"
    if doc_file.exists():
        return FileResponse(doc_file)
    return {"error": "doc.html not found"}


app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host=HOST, port=PORT, reload=False, workers=1)
