import mss
from PIL import Image

def capture_region(x: int, y: int, width: int, height: int) -> Image.Image:
    """
    Captures a region of the screen.
    
    Args:
        x: The left coordinate.
        y: The top coordinate.
        width: The width of the region.
        height: The height of the region.
        
    Returns:
        A PIL Image object.
    """
    with mss.mss() as sct:
        # mss handles multi-monitor setups automatically with coordinates
        monitor = {"top": y, "left": x, "width": width, "height": height}
        sct_img = sct.grab(monitor)
        
        # Convert to PIL Image
        img = Image.frombytes("RGB", sct_img.size, sct_img.bgra, "raw", "BGRX")
        return img
