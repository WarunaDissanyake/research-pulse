import io
import os
import numpy as np
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from tensorflow.keras.models import load_model
from PIL import Image

app = FastAPI()

# Load the model from the local filesystem
MODEL_PATH = 'models/test_pulse.keras'
model = load_model(MODEL_PATH)

IMG_SIZE = 650

async def preprocess_image(file: UploadFile) -> np.ndarray:
    contents = await file.read()
    try:
        img = Image.open(io.BytesIO(contents)).convert('L').resize((IMG_SIZE, IMG_SIZE))
    except Exception:
        raise HTTPException(status_code=400, detail='Invalid image file')
    arr = np.array(img, dtype=np.float32)
    arr = arr.reshape((1, IMG_SIZE, IMG_SIZE, 1)) / 255.0
    return arr

@app.get('/')
def health_check():
    return {'status': 'healthy'}

@app.post('/predict-image')
async def predict_image(file: UploadFile = File(...)):
    img_arr = await preprocess_image(file)
    pred = model.predict(img_arr)[0][0]
    label = 'alcohol' if pred > 0.5 else 'non alcohol'
    confidence = float(pred) if pred > 0.5 else 1 - float(pred)
    return JSONResponse({'prediction': label, 'confidence': round(confidence, 3)})

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=8000,reload=True)