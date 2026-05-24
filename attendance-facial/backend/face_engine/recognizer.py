import cv2
import numpy as np
from insightface.app import FaceAnalysis
import os
import pickle
from config import settings

class FaceRecognizer:

    def __init__(self):
        self.app = FaceAnalysis(name='buffalo_l')
        self.app.prepare(ctx_id=0)

        self.embedding_db = []
        self.db_path = "embeddings.pkl"

        self.load_db()

    def get_embeddings(self, frame):
        faces = self.app.get(frame)
        return [face.embedding for face in faces]
    
    def cosine_similarity(self, emb1, emb2):
        return np.dot(emb1, emb2)
    
    def recognize_face(self, frame):

        embeddings = self.get_embeddings(frame)

        if not embeddings:
            return []

        results = []

        for emb in embeddings:
            emb = emb / np.linalg.norm(emb)

            best_match = None
            best_score = 0

            for estudiante in self.embedding_db:
                score = self.cosine_similarity(emb, estudiante["embedding"])

                if score > best_score:
                    best_score = score
                    best_match = estudiante

            # Validación final con threshold
            if best_match and best_score >= settings.MIN_CONFIDENCE:
                results.append({
                    "codigo": best_match["codigo"],
                    "nombre": best_match["nombre"],
                    "confianza": float(best_score)
                })

        return results   

    def register_student(self, image_path, nombre, codigo):

        image = cv2.imread(image_path)
        embeddings = self.get_embeddings(image)

        if not embeddings:
            return False

        emb = embeddings[0]
        emb = emb / np.linalg.norm(emb)

        self.embedding_db.append({
            "codigo": codigo,
            "nombre": nombre,
            "embedding": emb
        })

        self.save_db()
        return True
    
    def delete_student(self, codigo):

        initial_len = len(self.embedding_db)

        self.embedding_db = [
            e for e in self.embedding_db if e["codigo"] != codigo
        ]

        self.save_db()
        return len(self.embedding_db) < initial_len

    def save_db(self):
        with open(self.db_path, "wb") as f:
            pickle.dump(self.embedding_db, f)

    def load_db(self):
        if os.path.exists(self.db_path):
            with open(self.db_path, "rb") as f:
                self.embedding_db = pickle.load(f)

recognizer = FaceRecognizer()