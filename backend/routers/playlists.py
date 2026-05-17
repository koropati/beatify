from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

import models, schemas
from deps import get_db, get_current_user

router = APIRouter(prefix="/api/playlists", tags=["playlists"])

@router.get("", response_model=List[schemas.Playlist])
def get_user_playlists(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    playlists = db.query(models.Playlist).filter(models.Playlist.owner_id == current_user.id).all()
    # Ensure songs are mapped to schemas properly
    result = []
    base_url = "http://localhost:8000"
    for playlist in playlists:
        playlist_schema = schemas.Playlist.model_validate(playlist)
        for song_schema, song in zip(playlist_schema.songs, playlist.songs):
            song_schema.file_url = f"{base_url}/api/songs/stream/{song.id}"
            if song.cover_image_path:
                song_schema.cover_image_url = f"{base_url}/api/image/{song.cover_image_path}"
        result.append(playlist_schema)
    return result

@router.post("", response_model=schemas.Playlist)
def create_playlist(playlist: schemas.PlaylistCreate, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    db_playlist = models.Playlist(name=playlist.name, owner_id=current_user.id)
    db.add(db_playlist)
    db.commit()
    db.refresh(db_playlist)
    return db_playlist

@router.post("/{playlist_id}/songs/{song_id}", response_model=schemas.Playlist)
def add_song_to_playlist(playlist_id: int, song_id: int, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    playlist = db.query(models.Playlist).filter(models.Playlist.id == playlist_id, models.Playlist.owner_id == current_user.id).first()
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist not found")
        
    song = db.query(models.Song).filter(models.Song.id == song_id).first()
    if not song:
        raise HTTPException(status_code=404, detail="Song not found")
        
    if song in playlist.songs:
        raise HTTPException(status_code=400, detail="Song already in playlist")
        
    playlist.songs.append(song)
    db.commit()
    db.refresh(playlist)
    
    # Process schema
    base_url = "http://localhost:8000"
    playlist_schema = schemas.Playlist.model_validate(playlist)
    for song_schema, s in zip(playlist_schema.songs, playlist.songs):
        song_schema.file_url = f"{base_url}/api/songs/stream/{s.id}"
        if s.cover_image_path:
            song_schema.cover_image_url = f"{base_url}/api/image/{s.cover_image_path}"
            
    return playlist_schema
