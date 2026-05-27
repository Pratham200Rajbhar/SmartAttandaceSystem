import os
import argparse
import logging
from typing import Optional

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("model_uploader")

LIVENESS_README = """---
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
- **Preprocessing**: Convert image to BGR, resize to (224, 224), normalize to [-1.0, 1.0] using (x / 127.5) - 1.0.
- **Output**: A single probability score between 0.0 and 1.0 (via Sigmoid). Near 1.0 = live, near 0.0 = spoof.
"""

BACKGROUND_README = """---
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

This repository contains the background validation model used in the **Smart Attendance System**. It verifies the background context of an attendance submission to ensure the check-in occurs within a valid classroom setting.
"""


def check_huggingface_hub() -> None:
    try:
        import huggingface_hub  # noqa: F401
    except ImportError as err:
        logger.error("The 'huggingface_hub' package is required but not installed.\nPlease install it using: pip install huggingface_hub")
        raise SystemExit(1) from err


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Upload Smart Attendance models to Hugging Face.")
    parser.add_argument("--token", type=str, help="Hugging Face Write Token (alternatively set HF_TOKEN env var)")
    parser.add_argument("--private", action="store_true", help="Make the uploaded repositories private")
    parser.add_argument("--prefix", type=str, default="smart-attendance", help="Prefix for model repository names")
    return parser.parse_args()


def retrieve_token(arg_token: Optional[str]) -> str:
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


def get_hf_username(token: str) -> str:
    from huggingface_hub import HfApi
    try:
        user = HfApi(token=token).whoami()
        name = user.get("name")
        if not name:
            logger.error("Failed to retrieve username from Hugging Face whoami response.")
            raise SystemExit(1)
        return str(name)
    except Exception as err:
        logger.error("Authentication with Hugging Face failed: %s", err)
        raise SystemExit(1) from err


def ensure_repo(token: str, repo_id: str, private: bool) -> None:
    from huggingface_hub import HfApi
    try:
        HfApi(token=token).create_repo(repo_id=repo_id, repo_type="model", private=private, exist_ok=True)
        logger.info("Repository verified/created: %s", repo_id)
    except Exception as err:
        logger.error("Failed to verify/create repository %s: %s", repo_id, err)
        raise SystemExit(1) from err


def upload_assets(token: str, repo_id: str, local_file: str, target_name: str, readme: str) -> None:
    from huggingface_hub import HfApi
    api = HfApi(token=token)
    try:
        api.upload_file(path_or_fileobj=readme.encode(), path_in_repo="README.md", repo_id=repo_id)
        api.upload_file(path_or_fileobj=local_file, path_in_repo=target_name, repo_id=repo_id)
        logger.info("Upload complete for %s. View at https://huggingface.co/%s", target_name, repo_id)
    except Exception as err:
        logger.error("Failed to upload assets to %s: %s", repo_id, err)
        raise SystemExit(1) from err


def main() -> None:
    check_huggingface_hub()
    args = parse_arguments()
    token = retrieve_token(args.token)
    username = get_hf_username(token)
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

    liveness_repo = f"{username}/{args.prefix}-liveness-detection"
    bg_repo = f"{username}/{args.prefix}-background-validation"

    ensure_repo(token, liveness_repo, args.private)
    ensure_repo(token, bg_repo, args.private)

    upload_assets(token, liveness_repo, os.path.join(base_dir, "models/liveness_detection/liveness_mobilenet_v1.h5"), "liveness_mobilenet_v2.h5", LIVENESS_README)
    upload_assets(token, bg_repo, os.path.join(base_dir, "models/background_validation/background_mobilenet_v1.h5"), "background_mobilenet_v1.h5", BACKGROUND_README)


if __name__ == "__main__":
    main()
