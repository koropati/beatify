import secrets
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

import models, schemas
from deps import get_db
from core.security import verify_password, get_password_hash, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES

router = APIRouter(prefix="/api/auth", tags=["auth"])

@router.post("/register", response_model=schemas.User)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    if db.query(models.User).filter(models.User.email == user.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    if db.query(models.User).filter(models.User.username == user.username).first():
        raise HTTPException(status_code=400, detail="Username already taken")

    user_count = db.query(models.User).count()
    db_user = models.User(
        email=user.email,
        username=user.username,
        hashed_password=get_password_hash(user.password),
        role="admin" if user_count == 0 else "user",
        is_verified=user_count == 0,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.post("/login", response_model=schemas.Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(
        data={"sub": user.username},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/forgot-password", response_model=schemas.MessageResponse)
def forgot_password(req: schemas.ForgotPassword, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == req.email).first()
    if not user:
        return {"message": "If this email exists, a reset token has been sent.", "token": None}

    token = str(secrets.randbelow(1_000_000)).zfill(6)
    user.reset_token = token
    user.reset_token_expiry = datetime.utcnow() + timedelta(minutes=15)
    db.commit()
    # In production: send token via email. For demo, returned in response.
    return {"message": "Reset token generated. Check your email.", "token": token}

@router.post("/reset-password", response_model=schemas.MessageResponse)
def reset_password(req: schemas.ResetPassword, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.reset_token == req.token).first()
    if not user or user.reset_token_expiry is None:
        raise HTTPException(status_code=400, detail="Invalid or expired token")
    if user.reset_token_expiry < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Token has expired")

    user.hashed_password = get_password_hash(req.new_password)
    user.reset_token = None
    user.reset_token_expiry = None
    db.commit()
    return {"message": "Password reset successfully"}
