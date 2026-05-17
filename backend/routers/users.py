from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
import os
import uuid

import models, schemas
from deps import get_db, get_current_user
from core.security import verify_password, get_password_hash

router = APIRouter(prefix="/api/users", tags=["users"])

BASE_URL = "https://beatify-api.satriakode.com"

def _build_user_response(user: models.User) -> schemas.User:
    user_data = schemas.User.model_validate(user)
    if user.profile_picture:
        user_data.profile_picture_url = f"{BASE_URL}/api/image/{user.profile_picture}"
    return user_data

@router.get("/me", response_model=schemas.User)
def read_users_me(current_user: models.User = Depends(get_current_user)):
    return _build_user_response(current_user)

@router.put("/me", response_model=schemas.User)
def update_profile(
    update: schemas.UpdateProfile,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    existing = db.query(models.User).filter(
        models.User.username == update.username,
        models.User.id != current_user.id,
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username already taken")
    current_user.username = update.username
    db.commit()
    db.refresh(current_user)
    return _build_user_response(current_user)

@router.put("/me/password", response_model=schemas.MessageResponse)
def change_password(
    req: schemas.ChangePassword,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not verify_password(req.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    current_user.hashed_password = get_password_hash(req.new_password)
    db.commit()
    return {"message": "Password changed successfully"}

@router.post("/me/picture", response_model=schemas.User)
async def upload_profile_picture(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File provided is not an image")

    ext = file.filename.split(".")[-1]
    filename = f"profile_{uuid.uuid4()}.{ext}"
    file_path = os.path.join("media", filename)

    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())

    current_user.profile_picture = filename
    db.commit()
    db.refresh(current_user)
    return _build_user_response(current_user)
