# main.py — Restart-Safe using PROCESSED FLAG (Stable Version)

import os
import time
import json
import io
import threading
from datetime import datetime, timezone

import requests
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from dotenv import load_dotenv
load_dotenv()

from utils import fruit_rot_condition, load_climate_model, load_cnn_model


# ========================
# ENV
# ========================

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON = os.getenv("SUPABASE_KEY")
SUPABASE_SERVICE = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

SENSOR_TABLE = "sensor_data"
HISTORY_TABLE = "fruit_rot_history"


# ========================
# FASTAPI
# ========================

app = FastAPI(title="ArecaSafe Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ========================
# MODELS
# ========================

climate_model = load_climate_model(os.getenv("CLIMATE_MODEL_PATH"))
cnn_model = load_cnn_model(os.getenv("CNN_MODEL_PATH"))
print("✅ Models loaded.")


# ========================
# STABLE REQUEST SESSION
# ========================

from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

session = requests.Session()

retry_cfg = Retry(
    total=5,
    backoff_factor=1.5,
    status_forcelist=[429, 500, 502, 503, 504],
    allowed_methods=["GET", "POST", "PATCH"]
)

adapter = HTTPAdapter(
    max_retries=retry_cfg,
    pool_connections=20,
    pool_maxsize=100
)

session.mount("https://", adapter)
session.mount("http://", adapter)

DEFAULT_TIMEOUT = 10


# ========================
# HELPERS
# ========================

def supabase_headers(service=False):
    key = SUPABASE_SERVICE if service else SUPABASE_ANON
    return {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json"
    }


# ========================
# FETCH ONLY UNPROCESSED ROWS
# ========================

def fetch_unprocessed():
    url = (
        f"{SUPABASE_URL}/rest/v1/{SENSOR_TABLE}"
        f"?select=*&processed=eq.false&order=created_at.asc"
    )

    try:
        r = session.get(url, headers=supabase_headers(False), timeout=DEFAULT_TIMEOUT)

        if r.status_code == 200:
            return r.json()

        print("❌ Fetch failed:", r.status_code, r.text)
        return []

    except requests.exceptions.ConnectionError:
        print("⚠ Supabase SSL dropped — retrying in 10s")
        time.sleep(10)
        return []

    except Exception as e:
        print("❌ Unexpected fetch error:", repr(e))
        time.sleep(10)
        return []


# ========================
# MARK SENSOR ROW AS PROCESSED
# ========================

def mark_processed(sensor_id):
    url = f"{SUPABASE_URL}/rest/v1/{SENSOR_TABLE}?id=eq.{sensor_id}"
    try:
        r = session.patch(
            url,
            headers=supabase_headers(True),
            data=json.dumps({"processed": True}),
            timeout=DEFAULT_TIMEOUT
        )
        if r.status_code not in (200, 204):
            print("❌ Failed marking processed:", r.status_code, r.text)

    except Exception as e:
        print("❌ Error marking processed:", repr(e))


# ========================
# SAVE HISTORY
# ========================

def insert_history(row):
    url = f"{SUPABASE_URL}/rest/v1/{HISTORY_TABLE}"

    try:
        r = session.post(
            url,
            headers=supabase_headers(True),
            data=json.dumps(row),
            timeout=DEFAULT_TIMEOUT
        )

        if r.status_code in (200, 201, 204):
            print("✔️ Insert OK:", r.status_code)
            return True

        print("❌ Insert error:", r.status_code, r.text)
        return False

    except Exception as e:
        print("❌ Insert failed:", repr(e))
        return False


# ========================
# COMPUTE & SAVE PREDICTION
# ========================

def compute_and_save(r):
    temp = float(r.get("temperature", 0))
    hum = float(r.get("humidity", 0))
    rain = float(r.get("rainfall", 0))
    sun = float(r.get("sunshine", 0))

    score, level = fruit_rot_condition(temp, hum, rain, sun)

    row = {
        "user_id": r.get("user_id"),
        "device_id": r.get("device_id"),
        "temperature": temp,
        "humidity": hum,
        "rainfall": rain,
        "sunshine": sun,
        "risk_score": score,
        "risk_level": level,
        "sensor_created_at": r.get("created_at"),
        "predicted_at": datetime.now(timezone.utc).isoformat()
    }

    if insert_history(row):
        print("📌 Prediction saved:", level)


# ========================
# REALTIME PROCESSOR (SAFE)
# ========================

def processor():
    print("🔁 Processor running (stable mode)")

    while True:
        try:
            rows = fetch_unprocessed()

            if rows:
                print(f"⚡ Found {len(rows)} new rows")
            else:
                print("⏳ Waiting for new sensor data...")

            for r in rows:
                compute_and_save(r)
                mark_processed(r["id"])

            # Your sensor sends data every 5 minutes → backend checks once per minute
            time.sleep(60)

        except Exception as e:
            print("❌ Processor error:", repr(e))
            time.sleep(30)


# ========================
# STARTUP
# ========================

@app.on_event("startup")
def startup():
    print("🚀 Backend started (processed-flag mode)")
    threading.Thread(target=processor, daemon=True).start()


# ========================
# IMAGE PREDICTION
# ========================

@app.post("/predict/image")
async def img(file: UploadFile = File(...)):
    if cnn_model is None:
        raise HTTPException(500, "CNN model not loaded")

    data = await file.read()

    from PIL import Image
    import numpy as np
    import io
    from tensorflow.keras.applications.efficientnet import preprocess_input

    try:
        img = Image.open(io.BytesIO(data)).convert("RGB").resize((224, 224))
    except:
        raise HTTPException(400, "Invalid image file")

    # Correct EfficientNet preprocessing
    arr = np.array(img).astype("float32")
    arr = preprocess_input(arr)
    arr = arr.reshape((1, 224, 224, 3))

    preds = cnn_model.predict(arr)

    LABELS = [
        "bud_borer",
        "healthy_foot",
        "healthy_leaf",
        "healthy_nut",
        "healthy_trunk",
        "mahali_koleroga",
        "stem_bleeding",
        "stem_cracking",
        "yellow_leaf_disease"
    ]

    idx = int(preds.argmax())
    confidence = float(preds.max())

    if confidence < 0.50:
        return {
            "class_index": None,
            "label": "unknown",
            "confidence": confidence,
            "message": "Image not recognized as an arecanut plant"
        }

    return {
        "class_index": idx,
        "label": LABELS[idx],
        "confidence": confidence,
        "message": "success",
        "probabilities": preds.tolist()[0]
    }

# ========================
# HEALTH CHECK
# ========================

@app.get("/health")
def h():
    return {"ok": True}
