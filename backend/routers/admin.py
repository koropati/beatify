from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import os

import models, schemas
from deps import get_db, get_current_admin_user
from routers.users import _build_user_response
from routers.songs import _with_media_urls, MEDIA_DIR

router = APIRouter(prefix="/api/admin", tags=["admin"])

@router.get("/users/unverified", response_model=List[schemas.User])
def get_unverified_users(
    current_admin: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    users = db.query(models.User).filter(models.User.is_verified == False).all()
    return [_build_user_response(user) for user in users]

@router.get("/users", response_model=List[schemas.User])
def list_users(
    current_admin: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    users = db.query(models.User).order_by(models.User.id).all()
    return [_build_user_response(user) for user in users]

@router.put("/users/{user_id}/verify", response_model=schemas.User)
def verify_user(
    user_id: int,
    current_admin: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if user.is_verified:
         raise HTTPException(status_code=400, detail="User is already verified")

    user.is_verified = True
    db.commit()
    db.refresh(user)
    return _build_user_response(user)

@router.put("/users/{user_id}", response_model=schemas.User)
def update_user(
    user_id: int,
    update: schemas.AdminUpdateUser,
    current_admin: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if update.username and update.username != user.username:
        if db.query(models.User).filter(
            models.User.username == update.username,
            models.User.id != user_id,
        ).first():
            raise HTTPException(status_code=400, detail="Username already taken")
        user.username = update.username

    if update.email and update.email != user.email:
        if db.query(models.User).filter(
            models.User.email == update.email,
            models.User.id != user_id,
        ).first():
            raise HTTPException(status_code=400, detail="Email already registered")
        user.email = update.email

    if update.role is not None:
        if update.role not in ("user", "admin"):
            raise HTTPException(status_code=400, detail="Invalid role")
        user.role = update.role

    if update.is_verified is not None:
        user.is_verified = update.is_verified

    db.commit()
    db.refresh(user)
    return _build_user_response(user)

@router.get("/songs", response_model=List[schemas.Song])
def list_all_songs(
    current_admin: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    songs = db.query(models.Song).order_by(models.Song.id).all()
    return [_with_media_urls(schemas.Song.model_validate(s), s) for s in songs]

@router.put("/songs/{song_id}", response_model=schemas.Song)
def update_song(
    song_id: int,
    update: schemas.AdminUpdateSong,
    current_admin: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    song = db.query(models.Song).filter(models.Song.id == song_id).first()
    if not song:
        raise HTTPException(status_code=404, detail="Song not found")

    if update.title is not None:
        song.title = update.title
    if update.artist is not None:
        song.artist = update.artist
    if update.album is not None:
        song.album = update.album

    db.commit()
    db.refresh(song)
    return _with_media_urls(schemas.Song.model_validate(song), song)

@router.delete("/songs/{song_id}", response_model=schemas.MessageResponse)
def delete_song(
    song_id: int,
    current_admin: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    song = db.query(models.Song).filter(models.Song.id == song_id).first()
    if not song:
        raise HTTPException(status_code=404, detail="Song not found")

    # Detach from any playlists before deleting to avoid orphaned associations.
    db.execute(
        models.playlist_songs.delete().where(
            models.playlist_songs.c.song_id == song_id
        )
    )

    for media in (song.file_path, song.cover_image_path):
        if media:
            path = os.path.join(MEDIA_DIR, media)
            if os.path.exists(path):
                os.remove(path)

    db.delete(song)
    db.commit()
    return {"message": "Song deleted successfully"}
