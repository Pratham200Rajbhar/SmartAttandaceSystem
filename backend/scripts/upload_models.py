import os
import argparse
import logging
from typing import Optional

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("model_uploader")

LIVENESS_README_TEMPLATE = """---
language: en
license: mit
tags:
- tensorflow
- keras
- computer-vision
- liveness-detection
- anti-spoofing
- smart-attendance
- mobilenetv2
---

# Smart Attendance - Liveness Detection Model

This repository contains the face liveness detection (anti-spoofing) model used in the **Smart Attendance System**. The model determines if a face presented to the camera is a real person (live) or a spoof attempt (e.g., a photo, video replay, or printout).

## Model Details
- **Architecture**: MobileNetV2 base (pretrained on ImageNet, fine-tuned) with a custom classification head.
- **Task**: Binary Classification (Liveness vs. Spoof)
- **Input Shape**: `(224, 224, 3)`
- **Preprocessing**: 
  - Convert image to BGR color space (since the model was trained on BGR images from OpenCV).
  - Resize to `(224, 224)`.
  - Normalize pixel values to the range `[-1.0, 1.0]` using `(x / 127.5) - 1.0`.
- **Output**: A single probability score between `0.0` and `1.0` (via Sigmoid activation).
  - Near `1.0` indicates a live person.
  - Near `0.0` indicates a spoof.

## Architecture Specification
```python
base_model = tf.keras.applications.MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights=None
)
x = base_model.output
x = tf.keras.layers.GlobalAveragePooling2D()(x)
x = tf.keras.layers.Dropout(0.001)(x)
outputs = tf.keras.layers.Dense(1, activation="sigmoid")(x)
model = tf.keras.models.Model(inputs=base_model.input, outputs=outputs)
```

## How to Use
To load and run inference with this model in Python:

```python
import cv2
import numpy as np
import tensorflow as tf

# Load the weights
model_path = "liveness_mobilenet_v2.h5"

# Reconstruct model and load weights
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

# Preprocessing function
def preprocess_liveness(face_crop: np.ndarray) -> np.ndarray:
    face_resized = cv2.resize(face_crop, (224, 224))
    face_normalized = (face_resized.astype(np.float32) / 127.5) - 1.0
    return np.expand_dims(face_normalized, axis=0)

# Run inference
# (Ensure face_crop is in BGR format before passing)
face_bgr = cv2.cvtColor(face_crop, cv2.COLOR_RGB2BGR)
input_tensor = preprocess_liveness(face_bgr)
prediction = model.predict(input_tensor)[0][0]
print(f"Liveness score: {prediction}")
```
"""

BACKGROUND_README_TEMPLATE = """---
language: en
license: mit
tags:
- tensorflow
- keras
- computer-vision
- classroom-detection
- background-validation
- smart-attendance
- mobilenetv1
---

# Smart Attendance - Background Validation Model

This repository contains the background validation model used in the **Smart Attendance System**. It is designed to verify the background context of an attendance submission to ensure the check-in occurs within a valid classroom setting, preventing spoofing attempts where users check in from home, dorm rooms, or external environments.

## Model Details
- **Architecture**: MobileNetV1 base with classification head.
- **Task**: Context/Background Verification
- **Input Shape**: `(224, 224, 3)`
- **Preprocessing**: 
  - Image resized to `(224, 224)`.
  - Preprocessed using standard MobileNet preprocessing (`tensorflow.keras.applications.mobilenet.preprocess_input`).
- **Output**: Softmax/classification score representing class probabilities of the background environment.

## How to Use
To load and run inference in Python:

```python
import cv2
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications.mobilenet import preprocess_input

# Load the model
model = tf.keras.models.load_model("background_mobilenet_v1.h5")

# Preprocessing
def preprocess_background(img_crop: np.ndarray) -> np.ndarray:
    img_resized = cv2.resize(img_crop, (224, 224))
    img_batch = np.expand_dims(img_resized, axis=0)
    return preprocess_input(img_batch.astype(np.float32))

# Run inference
input_tensor = preprocess_background(image)
prediction = model.predict(input_tensor)
```
"""


def check_huggingface_hub() -> None:
    """Verifies if the huggingface_hub package is installed."""
    try:
        import huggingface_hub  # noqa: F401
    except ImportError as err:
        logger.error(
            "The 'huggingface_hub' package is required but not installed.\n"
            "Please install it using: pip install huggingface_hub"
        )
        raise SystemExit(1) from err


def parse_arguments() -> argparse.Namespace:
    """Parses command-line arguments for the upload script."""
    parser = argparse.ArgumentParser(
        description="Upload Smart Attendance models to Hugging Face."
    )
    parser.add_argument(
        "--token",
        type=str,
        help="Hugging Face Write Token (alternatively set HF_TOKEN env var)",
    )
    parser.add_argument(
        "--private",
        action="store_true",
        help="Make the uploaded repositories private",
    )
    parser.add_argument(
        "--prefix",
        type=str,
        default="smart-attendance",
        help="Prefix for model repository names",
    )
    return parser.parse_args()


def retrieve_token(arg_token: Optional[str]) -> str:
    """Retrieves the Hugging Face API token from args, environment, or .env."""
    if arg_token:
        return arg_token

    token = os.environ.get("HF_TOKEN")
    if token:
        return token

    try:
        from dotenv import load_dotenv
        load_dotenv()
        token = os.environ.get("HF_TOKEN")
        if token:
            return token
    except ImportError:
        logger.warning(".env parsing skipped as 'python-dotenv' is not installed.")

    logger.error("Hugging Face API token not found. Please set HF_TOKEN env variable or pass --token.")
    raise SystemExit(1)


def fetch_username(token: str) -> str:
    """Retrieves the Hugging Face username using the provided API token."""
    from huggingface_hub import HfApi
    try:
        api = HfApi(token=token)
        user_info = api.whoami()
        username = user_info.get("name")
        if not username:
            logger.error("Failed to retrieve username from Hugging Face whoami response.")
            raise SystemExit(1)
        return str(username)
    except Exception as err:
        logger.error("Authentication with Hugging Face failed: %s", err)
        raise SystemExit(1) from err


def ensure_repo(token: str, repo_id: str, private: bool) -> None:
    """Ensures that the repository exists on Hugging Face."""
    from huggingface_hub import HfApi
    try:
        api = HfApi(token=token)
        api.create_repo(repo_id=repo_id, repo_type="model", private=private, exist_ok=True)
        logger.info("Repository verified/created: %s", repo_id)
    except Exception as err:
        logger.error("Failed to verify/create repository %s: %s", repo_id, err)
        raise SystemExit(1) from err


def upload_model_artifacts(
    token: str,
    repo_id: str,
    local_file: str,
    target_name: str,
    readme_content: str
) -> None:
    """Uploads the model card and model file to the repository."""
    from huggingface_hub import HfApi
    api = HfApi(token=token)
    try:
        api.upload_file(
            path_or_fileobj=readme_content.encode("utf-8"),
            path_in_repo="README.md",
            repo_id=repo_id,
        )
        api.upload_file(
            path_or_fileobj=local_file,
            path_in_repo=target_name,
            repo_id=repo_id,
        )
        logger.info("Upload complete for %s. View at https://huggingface.co/%s", target_name, repo_id)
    except Exception as err:
        logger.error("Failed to upload assets to %s: %s", repo_id, err)
        raise SystemExit(1) from err


def main() -> None:
    """Main execution flow for uploading models to Hugging Face."""
    check_huggingface_hub()
    args = parse_arguments()
    token = retrieve_token(args.token)
    username = fetch_username(token)

    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

    # Upload Liveness Model
    liveness_repo = f"{username}/{args.prefix}-liveness-detection"
    liveness_local = os.path.join(base_dir, "models/liveness_detection/liveness_mobilenet_v1.h5")
    ensure_repo(token, liveness_repo, args.private)
    upload_model_artifacts(token, liveness_repo, liveness_local, "liveness_mobilenet_v2.h5", LIVENESS_README_TEMPLATE)

    # Upload Background Model
    bg_repo = f"{username}/{args.prefix}-background-validation"
    bg_local = os.path.join(base_dir, "models/background_validation/background_mobilenet_v1.h5")
    ensure_repo(token, bg_repo, args.private)
    upload_model_artifacts(token, bg_repo, bg_local, "background_mobilenet_v1.h5", BACKGROUND_README_TEMPLATE)


if __name__ == "__main__":
    main()
