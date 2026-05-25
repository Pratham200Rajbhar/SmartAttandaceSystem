Building all these models is an exciting challenge for your Capstone project. To ensure your team meets the 18-week Agile timeline, the overarching strategy must be: **Leverage pre-trained models heavily, and only train from scratch when absolutely necessary.**

Here is the best practical roadmap to build and implement all the models for the Smart Attendance System.

ai_core/
│
├── 1_face_recognition/
│   ├── data/                     # Student selfies for testing
│   ├── weights/                  # Saved embeddings database
│   ├── Face_Recognition.ipynb    # Main workspace: DeepFace testing & similarity logic
│   ├── inference.py              # Tiny script for FastAPI to load the model
│   └── requirements.txt
│
├── 2_liveness_detection/
│   ├── data/                     # Real vs. Spoof test images
│   ├── weights/                  # Anti-spoofing model files (.pth / .onnx)
│   ├── Liveness_Training.ipynb   # Main workspace: MiniFASNet execution & evaluation
│   ├── inference.py              # Tiny script for FastAPI to load the model
│   └── requirements.txt
│
├── 3_background_validation/
│   ├── data/
│   │   ├── raw/                  # Campus photos
│   │   └── processed/            # Cleaned data
│   ├── weights/                  # custom_campus_background_v1.h5
│   ├── Background_Model.ipynb    # Main workspace: Transfer learning with MobileNetV2
│   ├── inference.py              # Tiny script for FastAPI to load the model
│   └── requirements.txt
│
├── 4_absentee_patterns/
│   ├── data/                     # CSV logs of attendance
│   ├── weights/                  # Saved scikit-learn models (.pkl)
│   ├── Anomaly_Detection.ipynb   # Main workspace: Scikit-learn isolation forests
│   ├── inference.py              # Tiny script for FastAPI to load the model
│   └── requirements.txt
│
├── shared_utils/
│   ├── __init__.py
│   └── image_prep.py             # Shared OpenCV resizing functions
│
├── .gitignore                    # Ignore ALL data/ and weights/ folders
└── decision_engine.py            # FastAPI imports the 4 small inference.py files here

### 1. Face Recognition: Use DeepFace (Pre-trained)

Do not build this from scratch. Building robust facial recognition requires millions of images.

* **The Tool:** Use the `deepface` Python library. It is a lightweight wrapper that lets you use state-of-the-art models like FaceNet, VGG-Face, or ArcFace with a few lines of code.
* **The Implementation:** 1.  When a student registers, pass their photo through DeepFace to generate a vector embedding (a list of numbers representing the face).
2.  Store this embedding in your PostgreSQL database.
3.  During attendance, extract the live embedding and use Scipy to calculate the cosine similarity against the database record.

### 2. Liveness Detection: Use Silent-Face-Anti-Spoofing (Pre-trained)

Liveness detection is the hardest model to train because "spoof" methods (screens, printed photos, masks) are highly varied.

* **The Tool:** Clone an open-source repository like **MiniFASNet** (often found under "Silent Face Anti-Spoofing" on GitHub). This aligns perfectly with your planned tech stack.
* **The Implementation:** These models usually expect a cropped face image as input and output a probability score (0.0 to 1.0) of whether the face is real or a spoof. You can import this model's inference script directly into your FastAPI backend and pass the same image you just used for Face Recognition.

### 3. Background Validation: Transfer Learning (Custom Training)

This is the one model you *must* train yourself, because what constitutes a "classroom" at Ganpat University might look different from classrooms in standard datasets.

* **The Tool:** Use TensorFlow/Keras with **MobileNetV2**. It is lightweight enough to eventually run on edge devices via TensorFlow Lite.
* **The Implementation:**
1. **Data Collection:** Spend two days taking hundreds of photos of campus classrooms (Valid) and hostels, canteens, or outdoors (Invalid).
2. **Training:** Load the pre-trained MobileNetV2 without its top layers. Add a new Dense layer with a Sigmoid activation function.
3. **Fine-tuning:** Train only your new layers on your custom campus dataset. This will output the background confidence score (0.0 to 1.0).



### 4. Absentee Pattern Detection: Scikit-Learn (Tabular ML)

This is an anomaly detection task rather than an image processing task.

* **The Tool:** Use Python's `scikit-learn` library.
* **The Implementation:** Apply an algorithm like **Isolation Forest**. You will feed it tabular data from your PostgreSQL database (e.g., frequency of absences, days of the week most often missed, consecutive missed days) to flag irregular patterns.

### 5. Tying it Together: The AI Decision Engine

This isn't a machine learning model, but a vital piece of standard Python logic inside your FastAPI server.

* **The Implementation:** Write a Python function that takes the float outputs from the three vision models and applies your exact formula: `(0.50 × face_score) + (0.30 × liveness_score) + (0.20 × background_score)`. If the final score is $\ge 0.75$ and the GPS validation passes, return a "Present" status.

---

Would you like me to map out the exact folder and directory structure for organizing these AI models within your FastAPI backend?
