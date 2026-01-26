FROM python:3.11-slim

# Evita archivos .pyc y asegura logs en tiempo real
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# 1. Dependencias del sistema (ffmpeg es vital para tus audios)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 2. Copiar requerimientos y actualizar PIP
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 3. Copiar el resto del código
COPY . .

EXPOSE 8080

# 4. Comando de inicio COMPATIBLE (Apps Script + Python)
CMD ["uvicorn", "mainAPI:app", \
     "--host", "0.0.0.0", \
     "--port", "8080", \
     "--loop", "uvloop", \
     "--http", "auto", \
     "--timeout-keep-alive", "650"]