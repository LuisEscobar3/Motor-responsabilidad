FROM python:3.11-slim

# Variables para logs en tiempo real en GCP
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Instalamos ffmpeg y dependencias de sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Instalamos uvicorn con soporte para todos los protocolos
RUN pip install --no-cache-dir uvicorn[standard] h2 httptools uvloop

COPY . .

EXPOSE 8080

# ✅ CONFIGURACIÓN COMPATIBLE:
# Quitamos "--http h2" y usamos "--http auto"
CMD ["uvicorn", "mainAPI:app", \
     "--host", "0.0.0.0", \
     "--port", "8080", \
     "--loop", "uvloop", \
     "--http", "auto", \
     "--timeout-keep-alive", "650"]