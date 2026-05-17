from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

import models, schemas
from deps import get_db, get_current_admin_user

router = APIRouter(prefix="/api/admin", tags=["admin"])

@router.get("/users/unverified", response_model=List[schemas.User])
def get_unverified_users(
    current_admin: models.User = Depends(get_current_admin_user), 
    db: Session = Depends(get_db)
):
    users = db.query(models.User).filter(models.User.is_verified == False).all()
    # Add profile picture base url if exists
    result = []
    base_url = "http://localhost:8000"
    for user in users:
        user_schema = schemas.User.model_validate(user)
        if user.profile_picture:
            user_schema.profile_picture_url = f"{base_url}/api/image/{user.profile_picture}"
        result.append(user_schema)
    return result

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

    # Convert to schema
    base_url = "http://localhost:8000"
    user_schema = schemas.User.model_validate(user)
    if user.profile_picture:
        user_schema.profile_picture_url = f"{base_url}/api/image/{user.profile_picture}"
        
    return user_schema
