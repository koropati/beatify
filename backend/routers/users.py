from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
import os
import uuid

import models, schemas
from deps import get_db, get_current_user

router = APIRouter(prefix="/api/users", tags=["users"])

@router.get("/me", response_model=schemas.User)
def read_users_me(current_user: models.User = Depends(get_current_user)):
    # Add base url for profile picture if it exists
    base_url = "http://localhost:8000"
    user_data = schemas.User.model_validate(current_user)
    if current_user.profile_picture:
        user_data.profile_picture_url = f"{base_url}/api/image/{current_user.profile_picture}"
    return user_data

@router.post("/me/picture", response_model=schemas.User)
async def upload_profile_picture(
    file: UploadFile = File(...), 
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File provided is not an image")

    # Generate unique filename
    ext = file.filename.split(".")[-1]
    filename = f"profile_{uuid.uuid4()}.{ext}"
    file_path = os.path.join("media", filename)

    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())

    current_user.profile_picture = filename
    db.commit()
    db.refresh(current_user)

    # Return updated user
    base_url = "http://localhost:8000"
    user_data = schemas.User.model_validate(current_user)
    user_data.profile_picture_url = f"{base_url}/api/image/{filename}"
    return user_data
