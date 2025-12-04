import os
import google.generativeai as genai
from PIL import Image
from src.core.config import Config

def extract_text(image: Image.Image) -> str:
    """
    Extracts text from an image using Gemini Flash.
    """
    # Try config first, then fall back to environment variable
    config = Config()
    api_key = config.get_api_key() or os.getenv("GEMINI_API_KEY")
    
    if not api_key:
        raise ValueError("Gemini API key not configured. Please set it in Settings or GEMINI_API_KEY environment variable.")
    
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel('gemini-2.5-flash')
    
    # Prompt optimized for pure OCR
    prompt = "Extract the text from this image. Return ONLY the extracted text. Do not describe the image. Do not use markdown code blocks."
    
    try:
        response = model.generate_content([prompt, image])
        return response.text
    except Exception as e:
        print(f"OCR Error: {e}")
        raise
