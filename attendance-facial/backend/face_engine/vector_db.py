
import logging
from datetime import datetime
from typing import List, Dict, Optional
import numpy as np

try:
    import pinecone
except ImportError:
    pinecone = None

from config import settings

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


class VectorDB:

    def __init__(self):
        """Inicializa conexión con Pinecone"""
        try:
            if pinecone is None:
                raise ImportError("pinecone no está instalado")
            
            logger.info("Inicializando conexión con Pinecone...")
            
            # Inicializar Pinecone
            pinecone.init(
                api_key=settings.PINECONE_API_KEY,
                environment=settings.PINECONE_ENV
            )
            
            # Crear o acceder al índice
            self.index_name = settings.PINECONE_INDEX_NAME
            
            # Verificar si el índice existe
            if self.index_name not in pinecone.list_indexes():
                logger.info(f"Creando índice '{self.index_name}'...")
                pinecone.create_index(
                    name=self.index_name,
                    dimension=settings.PINECONE_DIMENSION,  # 512 para buffalo_l
                    metric="cosine"  # Similitud coseno
                )
                logger.info(f"Índice '{self.index_name}' creado exitosamente")
            else:
                logger.info(f"Índice '{self.index_name}' existe")
            
            # Obtener referencia al índice
            self.index = pinecone.Index(self.index_name)
            logger.info("Pinecone conectado exitosamente")
            self.connected = True
        
        except Exception as e:
            logger.error(f"Error conectando a Pinecone: {e}")
            self.connected = False
            self.index = None

    def registrar_estudiante(
        self,
        embedding: np.ndarray,
        nombre: str,
        codigo: str,
        foto_url: Optional[str] = None
    ) -> bool:

        try:
            if not self.connected:
                logger.error("Pinecone no está conectado")
                return False
            
            # Crear ID único
            vector_id = f"{codigo}_{nombre.replace(' ', '_')}"
            
            # Metadatos
            metadata = {
                "nombre": nombre,
                "codigo": codigo,
                "timestamp": datetime.now().isoformat()
            }
            
            if foto_url:
                metadata["foto_url"] = foto_url
            
            # Convertir embedding a lista
            embedding_list = embedding.tolist() if isinstance(embedding, np.ndarray) else embedding
            
            # Upsert en Pinecone
            self.index.upsert([(
                vector_id,
                embedding_list,
                metadata
            )])
            
            logger.info(f"Estudiante {codigo} guardado en Pinecone")
            return True
        
        except Exception as e:
            logger.error(f"Error registrando estudiante en Pinecone: {e}")
            return False

    def buscar_estudiante(
        self,
        embedding: np.ndarray,
        top_k: int = 5,
        threshold: float = 0.80
    ) -> List[Dict]:

        try:
            if not self.connected:
                logger.error("Pinecone no está conectado")
                return []
            
            # Convertir embedding a lista
            embedding_list = embedding.tolist() if isinstance(embedding, np.ndarray) else embedding
            
            # Buscar en Pinecone
            resultados = self.index.query(
                vector=embedding_list,
                top_k=top_k,
                include_metadata=True
            )
            
            # Procesar resultados
            matches = []
            for match in resultados.matches:
                # Filtrar por threshold
                if match.score >= threshold:
                    matches.append({
                        "codigo": match.metadata.get("codigo"),
                        "nombre": match.metadata.get("nombre"),
                        "confianza": float(match.score),
                        "foto_url": match.metadata.get("foto_url")
                    })
            
            logger.info(f"Búsqueda Pinecone: {len(matches)} match(es) encontrados")
            return matches
        
        except Exception as e:
            logger.error(f"Error buscando en Pinecone: {e}")
            return []

    def eliminar_estudiante(self, codigo: str) -> bool:

        try:
            if not self.connected:
                logger.error("Pinecone no está conectado")
                return False
            
            # Eliminar por filtro de metadatos
            self.index.delete(
                filter={"codigo": {"$eq": codigo}}
            )
            
            logger.info(f"Estudiante {codigo} eliminado de Pinecone")
            return True
        
        except Exception as e:
            logger.error(f"Error eliminando estudiante en Pinecone: {e}")
            return False

    def actualizar_estudiante(
        self,
        embedding: np.ndarray,
        nombre: str,
        codigo: str,
        foto_url: Optional[str] = None
    ) -> bool:

        # Eliminar antiguo y crear nuevo
        self.eliminar_estudiante(codigo)
        return self.registrar_estudiante(embedding, nombre, codigo, foto_url)

    def obtener_estudiante(self, codigo: str) -> Optional[Dict]:

        try:
            if not self.connected:
                logger.error("Pinecone no está conectado")
                return None
            
            # Buscar por metadatos
            # Nota: Pinecone no soporta búsqueda exacta sin vector
            # Se necesitaría metadatos indexados
            logger.warning("Búsqueda por código requiere índice de metadatos en Pinecone")
            return None
        
        except Exception as e:
            logger.error(f"Error obteniendo estudiante: {e}")
            return None

    def get_stats(self) -> Optional[Dict]:

        try:
            if not self.connected:
                return None
            
            stats = self.index.describe_index_stats()
            logger.info(f"Stats Pinecone: {stats}")
            return stats
        
        except Exception as e:
            logger.error(f"Error obteniendo stats: {e}")
            return None


# Instancia global
try:
    if settings.USE_PINECONE and settings.PINECONE_API_KEY:
        vector_db = VectorDB()
        logger.info("VectorDB (Pinecone) instancia global creada")
    else:
        logger.warning("Pinecone deshabilitado o sin API key")
        vector_db = None
except Exception as e:
    logger.critical(f"Error crítico al crear VectorDB: {e}")
    vector_db = None