import cv2
import numpy as np
from insightface.app import FaceAnalysis
import os
import pickle
from pathlib import Path
from PIL import Image as PILImage
from deepface import DeepFace
from config import settings

app = FaceAnalysis(name='buffalo_l')
app.prepare(ctx_id=0)

THRESHOLD = 0.6

def obtener_rostro(image):
    faces = app.get(image)

    if len(faces) == 0:
        return None

    return faces[0].embedding

def reconocimiento(image, embedding_db):
    img = ver_imagen(image)
    emb = obtener_rostro(img)

def comparar_rostros(embedding1, embedding2):
    embedding1 = embedding1 / np.linalg.norm(embedding1)
    embedding2 = embedding2 / np.linalg.norm(embedding2)

    similitud = np.dot(embedding1, embedding2)
    return similitud 

similitud = comparar_rostros(embedding1, embedding2)
if similitud > THRESHOLD:
    reconocimiento = True
else:
    reconocimiento = False

def ver_imagen(file_bytes):
    np_arr = np.frombuffer(file_bytes, np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    return img



    if emb is None:
        return None

    best_match = None
    best_score = 0

    for estudiante in embedding_db:
        sim = compare_faces(emb, estudiante["embedding"])

        if sim > best_score:
            best_score = sim
            best_match = estudiante

    if best_score > 0.5:
        return {
            "estudiante": best_match,
            "confianza": best_score
        }

    return None

class FaceRecognizer:
    def __init__(self):
        self.known_embeddings = []
        self.known_names = []
        self.known_codes = []
        self.faces_dir = Path(settings.FACES_DIR)
        self.encodings_file = self.faces_dir / "encodings.pkl"
        self.faces_dir.mkdir(parents=True, exist_ok=True)
        self.model_name = "Facenet"  # Rápido y preciso
        self.load_encodings()

    def load_encodings(self):
        if self.encodings_file.exists():
            with open(self.encodings_file, "rb") as f:
                data = pickle.load(f)
                self.known_embeddings = data.get("embeddings", [])
                self.known_names = data.get("names", [])
                self.known_codes = data.get("codes", [])
            print(f"✅ {len(self.known_embeddings)} estudiantes cargados.")
        else:
            print("⚠️  No hay estudiantes registrados aún.")

    def save_encodings(self):
        with open(self.encodings_file, "wb") as f:
            pickle.dump({
                "embeddings": self.known_embeddings,
                "names": self.known_names,
                "codes": self.known_codes
            }, f)

    def _get_embedding(self, image_array: np.ndarray) -> np.ndarray | None:
        """Obtiene el embedding facial de un array numpy."""
        try:
            result = DeepFace.represent(
                img_path=image_array,
                model_name=self.model_name,
                enforce_detection=True,
                detector_backend="opencv"
            )
            return np.array(result[0]["embedding"])
        except Exception as e:
            print(f"⚠️  No se detectó rostro: {e}")
            return None

    def _load_image(self, image_path: str) -> np.ndarray:
        """Carga imagen como array RGB contíguo."""
        pil = PILImage.open(image_path).convert("RGB")
        return np.ascontiguousarray(np.array(pil, dtype=np.uint8))

    def register_student(self, image_path: str, nombre: str, codigo: str) -> bool:
        image = self._load_image(image_path)
        embedding = self._get_embedding(image)

        if embedding is None:
            return False

        self.known_embeddings.append(embedding)
        self.known_names.append(nombre)
        self.known_codes.append(codigo)
        self.save_encodings()
        print(f"✅ Estudiante {nombre} ({codigo}) registrado.")
        return True

    def recognize_face(self, frame: np.ndarray) -> list:
        """Recibe un frame BGR de OpenCV y retorna rostros reconocidos."""
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        rgb_frame = np.ascontiguousarray(rgb_frame)

        try:
            faces = DeepFace.extract_faces(
                img_path=rgb_frame,
                enforce_detection=True,
                detector_backend="opencv"
            )
        except Exception:
            return []  # No se detectaron rostros

        results = []
        for face_data in faces:
            face_array = (face_data["face"] * 255).astype(np.uint8)
            face_array = np.ascontiguousarray(face_array)
            embedding = self._get_embedding(face_array)

            nombre = "Desconocido"
            codigo = None
            confianza = None

            if embedding is not None and len(self.known_embeddings) > 0:
                distances = [
                    np.linalg.norm(embedding - known)
                    for known in self.known_embeddings
                ]
                best_idx = np.argmin(distances)
                best_distance = distances[best_idx]

                # Threshold para FaceNet (menor distancia = más similar)
                if best_distance < 10:
                    nombre = self.known_names[best_idx]
                    codigo = self.known_codes[best_idx]
                    confianza = round(1 - (best_distance / 20), 2)

            region = face_data.get("facial_area", {})
            results.append({
                "nombre": nombre,
                "codigo": codigo,
                "confianza": confianza,
                "location": (
                    region.get("y", 0),
                    region.get("x", 0) + region.get("w", 0),
                    region.get("y", 0) + region.get("h", 0),
                    region.get("x", 0)
                )
            })

        return results

    def delete_student(self, codigo: str) -> bool:
        if codigo not in self.known_codes:
            return False
        idx = self.known_codes.index(codigo)
        self.known_embeddings.pop(idx)
        self.known_names.pop(idx)
        self.known_codes.pop(idx)
        self.save_encodings()
        return True

recognizer = FaceRecognizer()

