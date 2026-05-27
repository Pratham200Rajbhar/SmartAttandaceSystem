import asyncio
import os
import shutil
import threading
from typing import List, Optional, Tuple

import cv2
import numpy as np
import tensorflow as tf
from deepface import DeepFace
from huggingface_hub import hf_hub_download
from tensorflow.keras.applications.mobilenet import preprocess_input

from app.core.logging_config import get_logger

logger = get_logger("app.ai")

os.environ.setdefault('TF_CPP_MIN_LOG_LEVEL', '3')
os.environ.setdefault('TF_ENABLE_ONEDNN_OPTS', '0')
os.environ.setdefault('CUDA_VISIBLE_DEVICES', '-1')

BASE_MODELS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../models"))
LIVENESS_REPO = "prathamrajbhar/smart-attendance-liveness-detection"
BACKGROUND_REPO = "prathamrajbhar/smart-attendance-background-validation"
LIVENESS_FILENAME = "liveness_mobilenet_v2.h5"
BACKGROUND_FILENAME = "background_mobilenet_v1.h5"

LIVENESS_MODEL_PATH_V2 = os.path.join(BASE_MODELS_DIR, "liveness_detection", "liveness_mobilenet_v2.h5")
LIVENESS_MODEL_PATH_V1 = os.path.join(BASE_MODELS_DIR, "liveness_detection", "liveness_mobilenet_v1.h5")
BACKGROUND_MODEL_PATH = os.path.join(BASE_MODELS_DIR, "background_validation", "background_mobilenet_v1.h5")


def _ensure_model_downloaded(repo_id: str, filename: str, local_path: str) -> str:
    if os.path.exists(local_path):
        return local_path
    logger.info("Downloading model: %s/%s", repo_id, filename)
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    try:
        downloaded = hf_hub_download(repo_id=repo_id, filename=filename, token=os.environ.get("HF_TOKEN"))
        shutil.copy(downloaded, local_path)
        return local_path
    except Exception as e:
        logger.error("Failed to download model from Hugging Face: %s", e, exc_info=True)
        raise RuntimeError(f"Could not load model {filename} from {repo_id}: {e}") from e


def _load_liveness_model(model_path: str) -> tf.keras.Model:
    base = tf.keras.applications.MobileNetV2(input_shape=(224, 224, 3), include_top=False, weights=None)
    x = base.output
    x = tf.keras.layers.GlobalAveragePooling2D(name="global_average_pooling2d_3")(x)
    x = tf.keras.layers.Dropout(0.001, name="dropout_3")(x)
    outputs = tf.keras.layers.Dense(1, activation="sigmoid", name="dense_3")(x)
    model = tf.keras.models.Model(inputs=base.input, outputs=outputs)
    model.load_weights(model_path, by_name=True)
    return model


_liveness_path = LIVENESS_MODEL_PATH_V2 if os.path.exists(LIVENESS_MODEL_PATH_V2) else (LIVENESS_MODEL_PATH_V1 if os.path.exists(LIVENESS_MODEL_PATH_V1) else LIVENESS_MODEL_PATH_V2)
_final_liveness_path = _ensure_model_downloaded(LIVENESS_REPO, LIVENESS_FILENAME, _liveness_path)
_final_background_path = _ensure_model_downloaded(BACKGROUND_REPO, BACKGROUND_FILENAME, BACKGROUND_MODEL_PATH)

liveness_model = _load_liveness_model(_final_liveness_path)
background_model = tf.keras.models.load_model(_final_background_path)

_liveness_lock = threading.Lock()
_background_lock = threading.Lock()
_deepface_lock = threading.Lock()


class AIOrchestrator:
    def _detect_and_crop_face(self, img: np.ndarray) -> Tuple[Optional[np.ndarray], Optional[Tuple[int, int, int, int]]]:
        try:
            with _deepface_lock:
                faces = DeepFace.extract_faces(img_path=img, detector_backend="opencv", enforce_detection=True)
            if not faces:
                return None, None
            fa = faces[0]["facial_area"]
            x, y, w, h = fa["x"], fa["y"], fa["w"], fa["h"]
            return img[y:y+h, x:x+w], (x, y, w, h)
        except Exception as e:
            logger.warning("DeepFace face extraction failed: %s", e)
            return None, None

    @staticmethod
    def _preprocess_liveness(face_crop: np.ndarray) -> np.ndarray:
        return np.expand_dims((cv2.resize(face_crop, (224, 224)).astype(np.float32) / 127.5) - 1.0, axis=0)

    @staticmethod
    def _preprocess_background(img: np.ndarray) -> np.ndarray:
        return preprocess_input(np.expand_dims(cv2.resize(img, (224, 224)), axis=0).astype(np.float32))

    def _run_face_comparison(self, stored_embedding: List[float], live_img: np.ndarray) -> float:
        if not stored_embedding or live_img is None:
            return 0.0
        try:
            with _deepface_lock:
                results = DeepFace.represent(img_path=live_img, model_name="Facenet", enforce_detection=False)
            if not results:
                return 0.0
            vec_s = np.array(stored_embedding, dtype=np.float32)
            vec_l = np.array(results[0]["embedding"], dtype=np.float32)
            norm_s, norm_l = np.linalg.norm(vec_s), np.linalg.norm(vec_l)
            if norm_s == 0.0 or norm_l == 0.0:
                return 0.0
            return max(0.0, min(1.0, float(np.dot(vec_s, vec_l) / (norm_s * norm_l))))
        except Exception as e:
            logger.error("DeepFace face comparison failed safely: %s", e, exc_info=True)
            return 0.0

    def _run_liveness_inference(self, face_crop: np.ndarray) -> float:
        if face_crop is None:
            return 0.0
        with _liveness_lock:
            return float(liveness_model.predict(self._preprocess_liveness(cv2.cvtColor(face_crop, cv2.COLOR_RGB2BGR)), verbose=0)[0][0])

    def _run_background_inference(self, img: np.ndarray) -> float:
        if img is None:
            return 0.0
        with _background_lock:
            return float(background_model.predict(self._preprocess_background(img), verbose=0)[0][0])

    def _run_embedding_extraction(self, image_path: str) -> List[float]:
        try:
            img = cv2.imread(image_path)
            if img is None:
                return []
            with _deepface_lock:
                results = DeepFace.represent(img_path=cv2.cvtColor(img, cv2.COLOR_BGR2RGB), model_name="Facenet", enforce_detection=True)
            return [float(v) for v in results[0]["embedding"]] if results else []
        except Exception as e:
            logger.error("DeepFace face embedding extraction failed safely: %s", e, exc_info=True)
            return []

    async def extract_face_embedding(self, image_path: str) -> List[float]:
        if not os.path.exists(image_path):
            return []
        try:
            return await asyncio.to_thread(self._run_embedding_extraction, image_path)
        except Exception as e:
            logger.error("Face embedding extraction thread run failed: %s", e, exc_info=True)
            return []

    async def analyze_attendance(self, image_path: str, face_embedding: List[float]) -> dict:
        if not os.path.exists(image_path):
            logger.warning("Image path does not exist for attendance analysis: %s", image_path)
            return {"face_score": 0.0, "liveness_score": 0.0, "background_score": 0.0}

        def _load_and_crop():
            img = cv2.imread(image_path)
            if img is None:
                return None, None, None
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            face_crop, _ = self._detect_and_crop_face(img_rgb)
            return img_rgb, face_crop, _

        try:
            img_rgb, face_crop, _ = await asyncio.to_thread(_load_and_crop)
        except Exception as e:
            logger.error("Failed to load and crop image: %s", e, exc_info=True)
            return {"face_score": 0.0, "liveness_score": 0.0, "background_score": 0.0}

        if img_rgb is None:
            return {"face_score": 0.0, "liveness_score": 0.0, "background_score": 0.0}

        try:
            face_score, liveness_score, bg_score = await asyncio.gather(
                asyncio.to_thread(self._run_face_comparison, face_embedding, img_rgb),
                asyncio.to_thread(self._run_liveness_inference, face_crop),
                asyncio.to_thread(self._run_background_inference, img_rgb),
            )
            return {"face_score": face_score, "liveness_score": liveness_score, "background_score": bg_score}
        except Exception as e:
            logger.error("Concurrent AI inference failed: %s", e, exc_info=True)
            return {"face_score": 0.0, "liveness_score": 0.0, "background_score": 0.0}
