FROM python:3.10-slim

WORKDIR /app

# Dependencias del sistema para OpenCV e InsightFace
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Pre-descargar modelos buffalo_l (~300MB) durante el build
RUN python -c "\
from insightface.app import FaceAnalysis; \
app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider']); \
app.prepare(ctx_id=-1); \
print('Modelos buffalo_l descargados')"

# Copiar el código
COPY . .

# Directorio para embeddings en memoria (se reconstituye desde Supabase al iniciar)
RUN mkdir -p data

EXPOSE 8000

CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
