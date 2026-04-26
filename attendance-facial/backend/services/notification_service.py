import firebase_admin
from firebase_admin import credentials, messaging
from pathlib import Path

_initialized = False

def init_firebase():
    global _initialized
    if not _initialized:
        try:
            cred_path = Path("firebase-service-account.json")
            if cred_path.exists():
                cred = credentials.Certificate(str(cred_path))
                firebase_admin.initialize_app(cred)
                _initialized = True
                print("✅ Firebase Admin SDK inicializado.")
            else:
                print("⚠️  firebase-service-account.json no encontrado.")
        except Exception as e:
            print(f"⚠️  Firebase Admin error: {e}")

def send_notification(token: str, title: str, body: str, data: dict = None):
    if not _initialized:
        print("⚠️  Firebase no inicializado.")
        return False
    try:
        payload = {"title": title, "body": body}
        if data:
            payload.update({k: str(v) for k, v in data.items()})

        message = messaging.Message(
            # Data-only message — bypasa restricciones MIUI
            data=payload,
            android=messaging.AndroidConfig(
                priority="high",
                ttl=3600,
            ),
            token=token,
        )
        messaging.send(message)
        print(f"✅ Notificación enviada.")
        return True
    except Exception as e:
        print(f"⚠️  Error: {e}")
        return False

def send_to_multiple(tokens: list, title: str, body: str, data: dict = None):
    if not _initialized or not tokens:
        return
    try:
        payload = {"title": title, "body": body}
        if data:
            payload.update({k: str(v) for k, v in data.items()})

        message = messaging.MulticastMessage(
            data=payload,
            android=messaging.AndroidConfig(
                priority="high",
                ttl=3600,
            ),
            tokens=tokens,
        )
        response = messaging.send_each_for_multicast(message)
        print(f"✅ Enviadas: {response.success_count}/{len(tokens)}")
    except Exception as e:
        print(f"⚠️  Error: {e}")