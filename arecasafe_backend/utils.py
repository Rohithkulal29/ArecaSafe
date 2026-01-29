# utils.py

import joblib
import numpy as np
from tensorflow.keras.models import load_model


# ============================================================
# LOAD MODELS
# ============================================================

def load_climate_model(path):
    return joblib.load(path)


def load_cnn_model(path):
    print("Loading CNN model from:", path)
    model = load_model(path, compile=False)
    model.build((None, 224, 224, 3))
    return model


# ============================================================
# FRUIT ROT LOGIC (Updated Rainfall-Aware)
# ============================================================

def fruit_rot_condition(temp, humidity, rainfall, sunshine):
    """
    Returns (score, level)
    score: 0 = low, 1 = moderate, 2 = high

    Fully updated and rainfall-aware:
    ✔ Rainfall dominates risk when high
    ✔ Uses humidity + sunshine + temperature second
    ✔ Safe fallback when rainfall sensor = 0
    """

    # Safe conversion for missing or string values
    try:
        t = float(temp or 0)
        h = float(humidity or 0)
        r = float(rainfall or 0)
        s = float(sunshine or 0)
    except Exception:
        t, h, r, s = 0.0, 0.0, 0.0, 0.0

    # =======================================================
    # 1️⃣ RAINFALL DOMINATES FRUIT ROT RISK
    # =======================================================

    # Very heavy rainfall → HIGH risk
    if r >= 100:
        return 2, "high"

    # Heavy rainfall → MODERATE risk
    if 50 <= r < 100:
        return 1, "moderate"

    # Moderate rainfall combined with humidity → HIGH
    if r >= 20 and h >= 85:
        return 2, "high"

    # =======================================================
    # 2️⃣ Temperature + Humidity + Sunshine (rain < 20mm)
    # =======================================================

    # HIGH risk (classic fruit rot weather)
    if (20 <= t <= 25) and (h >= 90) and (r >= 5 or s <= 1.5):
        return 2, "high"

    # MODERATE risk (warm + humid + some rain)
    if (25 < t <= 30 and h >= 80 and 1 <= r < 5) or (h >= 85 and r >= 2):
        return 1, "moderate"

    # =======================================================
    # 3️⃣ Zero-rainfall fallback (sensor unreliable)
    # =======================================================

    if r == 0:
        # High humidity + very low sunshine = fungal growth
        if h >= 92 and s < 1.5 and (20 <= t <= 28):
            return 2, "high"

        # Slightly lower humidity still risky
        if h >= 85 and s < 2.5:
            return 1, "moderate"

    # =======================================================
    # 4️⃣ DEFAULT → LOW RISK
    # =======================================================

    return 0, "low"
