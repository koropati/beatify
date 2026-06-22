import io
import os
import uuid

from PIL import Image, UnidentifiedImageError


def save_compressed_webp(
    raw: bytes,
    directory: str,
    prefix: str,
    max_size: int = 1024,
    quality: int = 80,
) -> str:
    """Convert raw image bytes to a compressed WebP file on disk.

    Downscales the longest edge to ``max_size`` to keep files small.
    Raises ``ValueError`` if ``raw`` is not a decodable image.
    Returns the generated filename (relative to ``directory``).
    """
    try:
        image = Image.open(io.BytesIO(raw))
        image.load()
    except (UnidentifiedImageError, OSError, ValueError):
        raise ValueError("Invalid image file")

    # WebP supports RGB/RGBA; normalize palette/CMYK/etc. to a safe mode.
    if image.mode not in ("RGB", "RGBA"):
        image = image.convert("RGBA" if "A" in image.getbands() else "RGB")

    image.thumbnail((max_size, max_size))

    os.makedirs(directory, exist_ok=True)
    filename = f"{prefix}_{uuid.uuid4()}.webp"
    image.save(os.path.join(directory, filename), "WEBP", quality=quality, method=6)
    return filename
