FROM python:3.11-slim

# Configuraciones esenciales de Python para Nube
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Instalamos ffmpeg para procesamiento de audio/video y herramientas de compilación
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Instalamos dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiamos el código fuente
COPY . .

EXPOSE 8080

# 🚀 Formato uvicorn con Workers para paralelismo real
# Se calculan 9 workers (2 * 4 CPUs + 1) para optimizar los 8 CPUs asignados
CMD ["uvicorn", "mainAPI:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "9", "--timeout-keep-alive", "650"]