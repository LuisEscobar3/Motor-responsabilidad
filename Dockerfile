FROM python:3.11-slim

# Configuraciones esenciales de Python para Nube
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Instalamos ffmpeg y herramientas base
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

# 🚀 Ajustado a 2 workers para balancear rendimiento y bajo consumo de RAM
# Esto evita que la instancia muera cuando el script externo recorta los recursos.
CMD ["uvicorn", "mainAPI:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "2", "--timeout-keep-alive", "650"]