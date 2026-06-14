from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List, Optional
import os
import uuid

import models, schemas
from deps import get_db, get_current_user, get_current_verified_user
from mutagen.mp3 import MP3

router = APIRouter(prefix="/api/songs", tags=["songs"])

MEDIA_DIR = "media"
os.makedirs(MEDIA_DIR, exist_ok=True)

# Public origin used to build absolute media URLs returned to clients.
PUBLIC_BASE_URL = os.getenv("PUBLIC_BASE_URL", "http://localhost:8000").rstrip("/")


def _with_media_urls(song_schema: schemas.Song, song: models.Song) -> schemas.Song:
    song_schema.file_url = f"{PUBLIC_BASE_URL}/api/songs/stream/{song.id}"
    if song.cover_image_path:
        song_schema.cover_image_url = f"{PUBLIC_BASE_URL}/api/image/{song.cover_image_path}"
    return song_schema

@router.get("", response_model=List[schemas.Song])
def read_songs(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    songs = db.query(models.Song).offset(skip).limit(limit).all()
    return [_with_media_urls(schemas.Song.model_validate(song), song) for song in songs]

@router.get("/stream/{song_id}")
def stream_song(song_id: int, db: Session = Depends(get_db)):
    song = db.query(models.Song).filter(models.Song.id == song_id).first()
    if song is None:
        raise HTTPException(status_code=404, detail="Song not found")
    
    file_path = os.path.join(MEDIA_DIR, song.file_path)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Audio file not found on server")

    return FileResponse(file_path, media_type="audio/mpeg")

@router.post("/upload", response_model=schemas.Song)
async def upload_song(
    title: str = Form(...),
    artist: str = Form(...),
    album: Optional[str] = Form(None),
    audio_file: UploadFile = File(...),
    cover_image: Optional[UploadFile] = File(None),
    current_user: models.User = Depends(get_current_verified_user),
    db: Session = Depends(get_db)
):
    if not audio_file.filename.endswith('.mp3'):
         raise HTTPException(status_code=400, detail="Only MP3 files are supported for now")

    # Save audio file
    audio_ext = audio_file.filename.split(".")[-1]
    audio_filename = f"song_{uuid.uuid4()}.{audio_ext}"
    audio_path = os.path.join(MEDIA_DIR, audio_filename)
    
    with open(audio_path, "wb") as buffer:
        buffer.write(await audio_file.read())

    # Try to get duration using mutagen (will add mutagen to requirements)
    duration = 0
    try:
        audio = MP3(audio_path)
        duration = int(audio.info.length)
    except Exception:
        pass # fallback to 0 if fails

    # Save cover image if exists
    cover_filename = None
    if cover_image:
        cover_ext = cover_image.filename.split(".")[-1]
        cover_filename = f"cover_{uuid.uuid4()}.{cover_ext}"
        cover_path = os.path.join(MEDIA_DIR, cover_filename)
        with open(cover_path, "wb") as buffer:
            buffer.write(await cover_image.read())

    new_song = models.Song(
        title=title,
        artist=artist,
        album=album,
        duration=duration,
        file_path=audio_filename,
        cover_image_path=cover_filename,
        owner_id=current_user.id
    )
    
    db.add(new_song)
    db.commit()
    db.refresh(new_song)

    return _with_media_urls(schemas.Song.model_validate(new_song), new_song)
