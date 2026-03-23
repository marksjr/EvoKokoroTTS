"""Evo KokoroTTS - Sintese de Voz pt-BR com IA."""
import uvicorn
from app.core.config import HOST, PORT

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=HOST,
        port=PORT,
        reload=False,
        workers=1,
        log_level="info",
    )
