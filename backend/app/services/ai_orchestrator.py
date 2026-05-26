import asyncio
from app.core.logging_config import get_logger
import os

import shutil

import threading

from typing import List, Optional, Tuple

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

os.environ['CUDA_VISIBLE_DEVICES'] = '-1'

import cv2

import numpy as np

from deepface import DeepFace

import tensorflow as tf

from tensorflow.keras.applications.mobilenet import preprocess_input

from huggingface_hub import hf_hub_download

logger = get_logger("app.ai")

BASE_MODELS_DIR = os.path.abspath(

    os.path.join(os.path.dirname(__file__), "../../models")

)

LIVENESS_REPO = "prathamrajbhar/smart-attendance-liveness-detection"

LIVENESS_FILENAME = "liveness_mobilenet_v2.h5"

BACKGROUND_REPO = "prathamrajbhar/smart-attendance-background-validation"

BACKGROUND_FILENAME = "background_mobilenet_v1.h5"

LIVENESS_MODEL_PATH_V2 = os.path.join(

    BASE_MODELS_DIR, "liveness_detection", "liveness_mobilenet_v2.h5"

)

LIVENESS_MODEL_PATH_V1 = os.path.join(

    BASE_MODELS_DIR, "liveness_detection", "liveness_mobilenet_v1.h5"

)

BACKGROUND_MODEL_PATH = os.path.join(

    BASE_MODELS_DIR, "background_validation", "background_mobilenet_v1.h5"

)

def _ensure_model_downloaded(repo_id: str, filename: str, local_path: str) -> str:

    if os.path.exists(local_path):

        logger.info("Model file found locally at: %s", local_path)

        return local_path

    logger.info("Model file not found locally. Downloading from Hugging Face: %s/%s", repo_id, filename)

    os.makedirs(os.path.dirname(local_path), exist_ok=True)

    token = os.environ.get("HF_TOKEN")

    try:

        downloaded_path = hf_hub_download(

            repo_id=repo_id,

            filename=filename,

            token=token

        )

        shutil.copy(downloaded_path, local_path)

        logger.info("Successfully downloaded and cached model to: %s", local_path)

        return local_path

    except Exception as e:

        logger.error("Failed to download model from Hugging Face: %s", e)

        raise RuntimeError(f"Could not load model {filename} from Hugging Face repository {repo_id}: {e}") from e

def _load_liveness_model(model_path: str) -> tf.keras.Model:

    base_model = tf.keras.applications.MobileNetV2(

        input_shape=(224, 224, 3),

        include_top=False,

        weights=None

    )

    x = base_model.output

    x = tf.keras.layers.GlobalAveragePooling2D(name="global_average_pooling2d_3")(x)

    x = tf.keras.layers.Dropout(0.001, name="dropout_3")(x)

    outputs = tf.keras.layers.Dense(1, activation="sigmoid", name="dense_3")(x)

    model = tf.keras.models.Model(inputs=base_model.input, outputs=outputs)

    model.load_weights(model_path, by_name=True)

    return model

if os.path.exists(LIVENESS_MODEL_PATH_V2):

    liveness_model_path = LIVENESS_MODEL_PATH_V2

elif os.path.exists(LIVENESS_MODEL_PATH_V1):

    liveness_model_path = LIVENESS_MODEL_PATH_V1

else:

    liveness_model_path = LIVENESS_MODEL_PATH_V2

final_liveness_path = _ensure_model_downloaded(LIVENESS_REPO, LIVENESS_FILENAME, liveness_model_path)

final_background_path = _ensure_model_downloaded(BACKGROUND_REPO, BACKGROUND_FILENAME, BACKGROUND_MODEL_PATH)

liveness_model = _load_liveness_model(final_liveness_path)

background_model = tf.keras.models.load_model(final_background_path)

liveness_lock = threading.Lock()

background_lock = threading.Lock()

deepface_lock = threading.Lock()

logger.info("✅ Native TensorFlow model weights initialized successfully inside backend.")

class AIOrchestrator:

    def _detect_and_crop_face(self, img: np.ndarray) -> Tuple[Optional[np.ndarray], Optional[Tuple[int, int, int, int]]]:

        try:

            with deepface_lock:

                faces = DeepFace.extract_faces(

                    img_path=img,

                    detector_backend="opencv",

                    enforce_detection=True

                )

            if not faces or len(faces) == 0:

                return None, None

            facial_area = faces[0]["facial_area"]

            x = facial_area["x"]

            y = facial_area["y"]

            w = facial_area["w"]

            h = facial_area["h"]

            return img[y:y+h, x:x+w], (x, y, w, h)

        except Exception as e:

            logger.warning("DeepFace face extraction failed: %s", e)

            return None, None

    def _preprocess_liveness(self, face_crop: np.ndarray) -> np.ndarray:

        face_resized = cv2.resize(face_crop, (224, 224))

        face_normalized = (face_resized.astype(np.float32) / 127.5) - 1.0

        return np.expand_dims(face_normalized, axis=0)

    def _preprocess_background(self, img_crop: np.ndarray) -> np.ndarray:

        img_resized = cv2.resize(img_crop, (224, 224))

        img_batch = np.expand_dims(img_resized, axis=0)

        return preprocess_input(img_batch.astype(np.float32))

    def _run_face_comparison(self, stored_embedding: List[float], live_img: np.ndarray) -> float:

        try:

            if not stored_embedding or live_img is None:

                return 0.0

            with deepface_lock:

                results = DeepFace.represent(img_path=live_img, model_name="Facenet", enforce_detection=False)

            if not results or len(results) == 0:

                return 0.0

            live_embedding = results[0]["embedding"]

            vec_stored = np.array(stored_embedding, dtype=np.float32)

            vec_live = np.array(live_embedding, dtype=np.float32)

            dot_val = np.dot(vec_stored, vec_live)

            norm_stored = np.linalg.norm(vec_stored)

            norm_live = np.linalg.norm(vec_live)

            if norm_stored == 0.0 or norm_live == 0.0:

                return 0.0

            similarity = float(dot_val / (norm_stored * norm_live))

            return max(0.0, min(1.0, similarity))

        except Exception as e:

            logger.error("DeepFace face comparison failed safely: %s", e)

            return 0.0

    def _run_liveness_inference(self, face_crop: np.ndarray) -> float:

        if face_crop is None:

            return 0.0

        face_crop_bgr = cv2.cvtColor(face_crop, cv2.COLOR_RGB2BGR)

        face_batch = self._preprocess_liveness(face_crop_bgr)

        with liveness_lock:

            prediction = liveness_model.predict(face_batch, verbose=0)[0]

        return float(prediction[0])

    def _run_background_inference(self, img: np.ndarray) -> float:

        return 1.0

    def _run_embedding_extraction(self, image_path: str) -> List[float]:

        try:

            img = cv2.imread(image_path)

            if img is None:

                return []

            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

            with deepface_lock:

                results = DeepFace.represent(img_path=img_rgb, model_name="Facenet", enforce_detection=True)

            if results and len(results) > 0:

                return [float(val) for val in results[0]["embedding"]]

            return []

        except Exception as e:

            logger.error("DeepFace face embedding extraction failed safely: %s", e)

            return []

    async def extract_face_embedding(self, image_path: str) -> List[float]:

        if not os.path.exists(image_path):

            return []

        try:

            return await asyncio.to_thread(self._run_embedding_extraction, image_path)

        except Exception as e:

            logger.error("Face embedding extraction thread run failed: %s", e)

            return []

    async def analyze_attendance(

        self, image_path: str, face_embedding: List[float]

    ) -> dict:

        if not os.path.exists(image_path):

            logger.warning("Image path does not exist for attendance analysis: %s", image_path)

            return {"face_score": 0.0, "liveness_score": 0.0, "background_score": 0.0}

        def _load_and_crop():

            img = cv2.imread(image_path)

            if img is None:

                return None, None, None

            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

            face_crop, face_coords = self._detect_and_crop_face(img_rgb)

            return img_rgb, face_crop, face_coords

        try:

            img_rgb, face_crop, face_coords = await asyncio.to_thread(_load_and_crop)

        except Exception as e:

            logger.error("Failed to load and crop image: %s", e)

            return {"face_score": 0.0, "liveness_score": 0.0, "background_score": 0.0}

        if img_rgb is None:

            return {"face_score": 0.0, "liveness_score": 0.0, "background_score": 0.0}

        try:

            face_task = asyncio.to_thread(self._run_face_comparison, face_embedding, img_rgb)

            liveness_task = asyncio.to_thread(self._run_liveness_inference, face_crop)

            background_task = asyncio.to_thread(self._run_background_inference, img_rgb)

            face_score, liveness_score, background_score = await asyncio.gather(

                face_task, liveness_task, background_task

            )

        except Exception as e:

            logger.error("Concurrent AI inference failed: %s", e)

            return {"face_score": 0.0, "liveness_score": 0.0, "background_score": 0.0}

        return {

            "face_score": face_score,

            "liveness_score": liveness_score,

            "background_score": background_score

        }

