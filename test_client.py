import sys
import httpx
import asyncio
import os
import time
from google.cloud import storage

# --- CONFIGURACIÓN GCP ---
PROJECT_ID = "sb-iapatrimoniales-dev"
BUCKET_NAME = "bucket-motor-responsabilidad"

storage_client = storage.Client(project=PROJECT_ID)


def verificar_descarga_completa(blob_name):
    try:
        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(blob_name)
        t_descarga_ini = time.perf_counter()
        contenido = blob.download_as_bytes()
        t_descarga_fin = time.perf_counter() - t_descarga_ini
        tamano_mb = len(contenido) / (1024 * 1024)
        print(f"📥 [VERIFICACIÓN] Descarga exitosa: {blob_name} ({tamano_mb:.2f} MB) en {t_descarga_fin:.2f}s")
        return True
    except Exception as e:
        print(f"❌ [VERIFICACIÓN] Error descargando {blob_name}: {e}")
        return False


def subir_a_gcs(ruta_local):
    if not os.path.exists(ruta_local):
        print(f"⚠️ Archivo no encontrado: {ruta_local}")
        return None
    nombre_archivo = os.path.basename(ruta_local)
    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(nombre_archivo)
    print(f"📤 Subiendo {nombre_archivo}...", end=" ", flush=True)
    blob.upload_from_filename(ruta_local)
    print("✅")
    if verificar_descarga_completa(nombre_archivo):
        return f"gs://{BUCKET_NAME}/{nombre_archivo}"
    else:
        return None


async def ejecutar_test():
    # URL actualizada al nombre del servicio que definimos
    url_api = "https://ia-mv-motor-responsabilidad-993828145189.us-east1.run.app/process-case"

    archivos = {
        "pdf": "ejemplo/sebastian.ortiz.matiz@segurosbolivar.com - 15400065559/15400065559.pdf",
        "audio1": "ejemplo/sebastian.ortiz.matiz@segurosbolivar.com - 15400065559/Llamada1-10e45b09-4ef7-426d-b05f-d45307b2170f.MP3",
        "audio2": "ejemplo/sebastian.ortiz.matiz@segurosbolivar.com - 15400065559/Llamada1-e9181c80-9ec7-4d8f-aed5-8c3b71b7cf09.MP3"
    }

    print("\n🚀 [PASO 1] Iniciando Subida y Verificación...")
    uris = {}
    for key, path in archivos.items():
        uri = subir_a_gcs(path)
        if not uri:
            print(f"🛑 FALLO CRÍTICO en subida de {key}")
            return
        uris[key] = uri

    payload = {
        "case_id": f"TEST-GCS-{int(time.time())}",
        "urls_visuales": [uris["pdf"]],
        "urls_audios": [uris["audio1"], uris["audio2"]],
        "urls_videos": []
    }

    print(f"\n📡 [PASO 2] Enviando a Cloud Run (Modo Compatible)...")

    # AJUSTE CRÍTICO:
    # 1. Desactivamos http2 temporalmente para asegurar que el proxy no resetee la conexión.
    # 2. El timeout debe ser None o muy alto (600s) para esperar a la IA.
    async with httpx.AsyncClient(http2=False, timeout=600.0) as client:
        try:
            t_ini = time.perf_counter()
            response = await client.post(url_api, json=payload)
            t_total = time.perf_counter() - t_ini

            print(f"⏱️ Tiempo de respuesta del modelo: {t_total:.2f}s")

            if response.status_code == 200:
                print("✅ API completada con éxito.")
                data = response.json()
                # Ajusta la impresión según la estructura de tu JSON de respuesta
                print("Resultado:", str(data)[:300], "...")
            else:
                print(f"❌ Error API ({response.status_code}): {response.text}")

        except Exception as e:
            print(f"❌ Error de conexión: {e}")


if __name__ == "__main__":
    asyncio.run(ejecutar_test())