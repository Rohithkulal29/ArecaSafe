# auth.py
import os
import time
from typing import Optional

import jwt
from fastapi import Header, HTTPException

# Provide SUPABASE_JWT_SECRET in your .env
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET")

if not SUPABASE_JWT_SECRET:
    # If not provided we'll still allow (but will fail verification)
    print("⚠️ SUPABASE_JWT_SECRET not set. Token verification will fail unless you set it.")

def get_current_user(authorization: Optional[str] = Header(None)):
    """
    FastAPI dependency to validate Supabase access_token (JWT).
    Expects header: Authorization: Bearer <access_token>
    Returns user_id (sub) if valid, otherwise raises HTTPException 401.
    """
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization header.")

    if not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Invalid Authorization header format. Use 'Bearer <token>'")

    token = authorization.split(" ", 1)[1].strip()

    try:
        # verify signature, expiration and algorithm
        payload = jwt.decode(token, SUPABASE_JWT_SECRET, algorithms=["HS256"], options={"verify_aud": False})
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token invalid: expired")
    except jwt.InvalidSignatureError:
        raise HTTPException(status_code=401, detail="Token invalid: signature mismatch")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Token invalid: {str(e)}")

    # Supabase uses 'sub' for user id
    user_id = payload.get("sub") or payload.get("user_id") or payload.get("uid")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token: no user id")
    # You may also inspect payload for roles etc if needed
    return user_id
