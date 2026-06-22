from pydantic import BaseModel, EmailStr
from typing import Optional, List

# --- Tokens ---
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

# --- User ---
class UserBase(BaseModel):
    email: EmailStr
    username: str

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    profile_picture_url: Optional[str] = None
    role: str
    is_verified: bool

    class Config:
        from_attributes = True

# --- Song ---
class SongBase(BaseModel):
    title: str
    artist: str
    album: Optional[str] = None
    duration: int

class SongCreate(SongBase):
    file_path: str
    cover_image_path: Optional[str] = None
    owner_id: Optional[int] = None

class Song(SongBase):
    id: int
    file_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    owner_id: Optional[int] = None

    class Config:
        from_attributes = True

# --- User Actions ---
class UpdateProfile(BaseModel):
    username: str
    email: Optional[EmailStr] = None

class AdminUpdateUser(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None
    role: Optional[str] = None
    is_verified: Optional[bool] = None

class AdminUpdateSong(BaseModel):
    title: Optional[str] = None
    artist: Optional[str] = None
    album: Optional[str] = None

class ChangePassword(BaseModel):
    current_password: str
    new_password: str

class ForgotPassword(BaseModel):
    email: EmailStr

class ResetPassword(BaseModel):
    token: str
    new_password: str

class MessageResponse(BaseModel):
    message: str
    token: Optional[str] = None

# --- Playlist ---
class PlaylistBase(BaseModel):
    name: str

class PlaylistCreate(PlaylistBase):
    pass

class Playlist(PlaylistBase):
    id: int
    owner_id: int
    songs: List[Song] = []

    class Config:
        from_attributes = True
