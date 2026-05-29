import cv2
import numpy as np
from insightface.app import FaceAnalysis
import os
import pickle
from config import settings
from database import supabase


class FaceRecognizer:

    def __init__(self):
        self.app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
        self.app.prepare(ctx_id=-1)

        self.embedding_db = []
        self.db_path = settings.EMBEDDINGS_DB_PATH
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)

        self.load_db()

    # ── Utilidades ─────────────────────────────────────────

    def _get_face_embeddings(self, frame):
        faces = self.app.get(frame)
        return [face.embedding / np.linalg.norm(face.embedding) for face in faces]

    def _cosine(self, a, b):
        return float(np.dot(a, b))

    # ── Registro ───────────────────────────────────────────

    def register_student(self, image_paths, nombre, codigo):
        """Registra con 1..N fotos.
        Guarda todos los embeddings individuales + el promedio.
        Retorna el embedding promedio como lista, o None si ninguna foto tiene rostro.
        """
        if isinstance(image_paths, str):
            image_paths = [image_paths]

        all_embs = []
        for path in image_paths:
            image = cv2.imread(path)
            if image is None:
                continue
            embs = self._get_face_embeddings(image)
            if embs:
                all_embs.append(embs[0])

        if not all_embs:
            return None

        avg = np.mean(all_embs, axis=0)
        avg = avg / np.linalg.norm(avg)

        self.embedding_db = [e for e in self.embedding_db if e["codigo"] != codigo]
        self.embedding_db.append({
            "codigo":     codigo,
            "nombre":     nombre,
            "embedding":  avg,           # promedio normalizado
            "embeddings": all_embs,      # todas las muestras individuales
        })
        self.save_db()
        return avg.tolist()

    # ── Reconocimiento ─────────────────────────────────────

    def recognize_face(self, frame):
        """Reconoce todos los rostros en el frame.
        Usa el máximo score entre el promedio y las muestras individuales.
        """
        face_embs = self._get_face_embeddings(frame)
        if not face_embs:
            return []

        results = []
        for emb in face_embs:
            best_match = None
            best_score = 0.0

            for estudiante in self.embedding_db:
                # Score contra el embedding promedio
                score = self._cosine(emb, estudiante["embedding"])

                # Score máximo contra las muestras individuales (si existen)
                for ind_emb in estudiante.get("embeddings", []):
                    score = max(score, self._cosine(emb, ind_emb))

                if score > best_score:
                    best_score = score
                    best_match = estudiante

            if best_match and best_score >= settings.MIN_CONFIDENCE:
                results.append({
                    "codigo":    best_match["codigo"],
                    "nombre":    best_match["nombre"],
                    "confianza": best_score,
                })

        return results

    def get_best_match_for(self, frame, codigo):
        """Score máximo para un estudiante específico (sin threshold)."""
        face_embs = self._get_face_embeddings(frame)
        if not face_embs:
            return 0.0, False

        emb = face_embs[0]
        best_score = 0.0

        for estudiante in self.embedding_db:
            if estudiante["codigo"] != codigo:
                continue
            score = self._cosine(emb, estudiante["embedding"])
            for ind_emb in estudiante.get("embeddings", []):
                score = max(score, self._cosine(emb, ind_emb))
            best_score = max(best_score, score)

        return best_score, True

    # ── Borrar ─────────────────────────────────────────────

    def delete_student(self, codigo):
        initial_len = len(self.embedding_db)
        self.embedding_db = [e for e in self.embedding_db if e["codigo"] != codigo]
        self.save_db()
        return len(self.embedding_db) < initial_len

    # ── Persistencia ───────────────────────────────────────

    def save_db(self):
        with open(self.db_path, "wb") as f:
            pickle.dump(self.embedding_db, f)

    def load_db(self):
        if os.path.exists(self.db_path):
            with open(self.db_path, "rb") as f:
                self.embedding_db = pickle.load(f)
            print(f"[recognizer] {len(self.embedding_db)} embeddings cargados desde pickle")
        else:
            self._load_from_supabase()

    def _load_from_supabase(self):
        """Carga embeddings desde Supabase (usado en Railway donde no hay pickle)."""
        try:
            result = supabase.table("estudiantes") \
                .select("codigo,nombre,embedding") \
                .not_.is_("embedding", "null") \
                .execute()
            for row in result.data:
                if row.get("embedding"):
                    avg = np.array(row["embedding"], dtype=np.float32)
                    avg = avg / np.linalg.norm(avg)
                    self.embedding_db.append({
                        "codigo":     row["codigo"],
                        "nombre":     row["nombre"],
                        "embedding":  avg,
                        "embeddings": [avg],
                    })
            print(f"[recognizer] {len(self.embedding_db)} embeddings cargados desde Supabase")
        except Exception as e:
            print(f"[recognizer] Error cargando desde Supabase: {e}")


recognizer = FaceRecognizer()
