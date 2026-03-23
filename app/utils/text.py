import re
import unicodedata
from app.core.config import CHUNK_TARGET_MIN_CHARS, CHUNK_TARGET_MAX_CHARS, CHUNK_ABSOLUTE_MAX_CHARS


def normalize_unicode(text: str) -> str:
    """Normaliza texto para NFC (forma composta).
    Garante que 'ã' seja um único caractere e não 'a' + '~' separados.
    Essencial para consistência na síntese de pt-BR."""
    return unicodedata.normalize('NFC', text)


def normalize_special_chars(text: str) -> str:
    """Normaliza caracteres tipográficos para equivalentes simples."""
    # Aspas tipográficas → aspas simples
    text = re.sub(r'[\u201C\u201D\u201E\u201F\u00AB\u00BB]', '"', text)
    text = re.sub(r'[\u2018\u2019\u201A\u201B]', "'", text)
    # Travessão e meia-risca → vírgula (pausa natural na fala)
    text = re.sub(r'\s*[\u2013\u2014]\s*', ', ', text)
    # Reticências Unicode → três pontos
    text = text.replace('\u2026', '...')
    # Espaços especiais (no-break, thin, etc.) → espaço normal
    text = re.sub(r'[\u00A0\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F]', ' ', text)
    return text


def preprocess_text_ptbr(text: str) -> str:
    """Pré-processamento de texto para pt-BR.
    Normaliza Unicode, expande abreviações e limpa formatação."""
    text = text.strip()

    # Normalizar Unicode (NFC) — crítico para acentos pt-BR
    text = normalize_unicode(text)

    # Normalizar caracteres tipográficos
    text = normalize_special_chars(text)

    # Normalizar espaços múltiplos
    text = re.sub(r'[ \t]+', ' ', text)
    # Normalizar quebras de linha múltiplas
    text = re.sub(r'\n{3,}', '\n\n', text)

    # Abreviações comuns pt-BR
    replacements = {
        r'\bDr\.\b': 'Doutor',
        r'\bDra\.\b': 'Doutora',
        r'\bSr\.\b': 'Senhor',
        r'\bSra\.\b': 'Senhora',
        r'\bSrta\.\b': 'Senhorita',
        r'\bProf\.\b': 'Professor',
        r'\bProfa\.\b': 'Professora',
        r'\bEng\.\b': 'Engenheiro',
        r'\bAdv\.\b': 'Advogado',
        r'\bAv\.\b': 'Avenida',
        r'\bR\.\b': 'Rua',
        r'\bArt\.\b': 'Artigo',
        r'\barts\.\b': 'artigos',
        r'\btel\.\b': 'telefone',
        r'\bcel\.\b': 'celular',
        r'\bLtda\.\b': 'Limitada',
        r'\bCia\.\b': 'Companhia',
        r'\bS\.A\.\b': 'Sociedade Anônima',
        r'\bDepto\.\b': 'Departamento',
        r'\bDept\.\b': 'Departamento',
        r'\bMin\.\b': 'Ministério',
        r'\bGov\.\b': 'Governo',
        r'\betc\.\b': 'etcétera',
        r'\bpág\.\b': 'página',
        r'\bpágs\.\b': 'páginas',
        r'\bvol\.\b': 'volume',
        r'\bcap\.\b': 'capítulo',
        r'\bex\.\b': 'exemplo',
        r'\bobs\.\b': 'observação',
        r'\baprox\.\b': 'aproximadamente',
        r'\bqtd\.\b': 'quantidade',
        r'\bqtde\.\b': 'quantidade',
    }
    for pattern, replacement in replacements.items():
        text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

    # nº / n° / Nº / N° (ordinal º e grau °)
    text = re.sub(r'\b[nN][°º]\s*', 'número ', text)

    # Expandir números ordinais comuns (º e ° tratados igualmente)
    ordinals_masc = {
        '1': 'primeiro', '2': 'segundo', '3': 'terceiro',
        '4': 'quarto', '5': 'quinto', '6': 'sexto',
        '7': 'sétimo', '8': 'oitavo', '9': 'nono', '10': 'décimo',
    }
    ordinals_fem = {
        '1': 'primeira', '2': 'segunda', '3': 'terceira',
        '4': 'quarta', '5': 'quinta', '6': 'sexta',
        '7': 'sétima', '8': 'oitava', '9': 'nona', '10': 'décima',
    }
    for num, word in ordinals_masc.items():
        text = re.sub(rf'\b{num}[ºo°]\b', word, text)
    for num, word in ordinals_fem.items():
        text = re.sub(rf'\b{num}[ªa]\b', word, text)

    # & → e
    text = re.sub(r'\s*&\s*', ' e ', text)

    # Expandir R$ → reais
    text = re.sub(r'R\$\s*(\d)', r'\1 reais', text)

    # Expandir US$ → dólares
    text = re.sub(r'US\$\s*(\d)', r'\1 dólares', text)

    # Expandir € → euros
    text = re.sub(r'€\s*(\d)', r'\1 euros', text)

    # Expandir % → por cento
    text = re.sub(r'(\d)\s*%', r'\1 por cento', text)

    # Expandir ª e º soltos após números maiores (ex: 15º → 15o → modelo lê)
    # Apenas normaliza o caractere especial para letra simples
    text = re.sub(r'(\d+)[°º]', r'\1o', text)
    text = re.sub(r'(\d+)ª', r'\1a', text)

    # Limpar espaços duplos gerados pelas substituições
    text = re.sub(r'  +', ' ', text)

    return text


def split_into_sentences(text: str) -> list[str]:
    """Divide texto em sentenças respeitando regras pt-BR.
    Lida com reticências (...), pontuação combinada (?!), e quebras de linha."""
    # Primeiro converter reticências em marcador temporário para preservar na sentença
    text = re.sub(r'\.{3}', '\u2026', text)
    # Split em pontuação final, mantendo a pontuação com a sentença
    parts = re.split(r'(?<=[.!?;:\u2026])\s+', text)
    # Restaurar reticências e dividir em quebras de linha
    sentences = []
    for part in parts:
        part = part.replace('\u2026', '...')
        sub_parts = re.split(r'\n+', part)
        sentences.extend(s.strip() for s in sub_parts if s.strip())
    return sentences


def chunk_text(text: str) -> list[str]:
    """Agrupa sentenças em chunks respeitando limites do modelo.
    Chunks menores = melhor qualidade (menos artefatos).
    Chunks muito pequenos = perda de contexto prosódico."""
    sentences = split_into_sentences(text)
    chunks = []
    current_chunk = ""

    for sentence in sentences:
        # Se a sentença sozinha excede o máximo absoluto, dividir por vírgulas
        if len(sentence) > CHUNK_ABSOLUTE_MAX_CHARS:
            if current_chunk:
                chunks.append(current_chunk.strip())
                current_chunk = ""
            sub_parts = re.split(r'(?<=,)\s+', sentence)
            sub_chunk = ""
            for sp in sub_parts:
                if len(sub_chunk) + len(sp) + 1 <= CHUNK_TARGET_MAX_CHARS:
                    sub_chunk = f"{sub_chunk} {sp}".strip() if sub_chunk else sp
                else:
                    if sub_chunk:
                        chunks.append(sub_chunk.strip())
                    sub_chunk = sp
            if sub_chunk:
                chunks.append(sub_chunk.strip())
            continue

        candidate = f"{current_chunk} {sentence}".strip() if current_chunk else sentence

        if len(candidate) <= CHUNK_TARGET_MAX_CHARS:
            current_chunk = candidate
        else:
            # Chunk atual já tem tamanho bom, salvar e começar novo
            if current_chunk:
                chunks.append(current_chunk.strip())
            current_chunk = sentence

    if current_chunk:
        chunks.append(current_chunk.strip())

    return chunks
