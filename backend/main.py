from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
import os
import models
from database import engine

# Import routers
from routers import auth, users, songs, playlists, admin

models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Beatify API",
    description="API untuk aplikasi music streaming Beatify. Mendukung fitur autentikasi, manajemen profil, playlist, dan streaming file audio.",
    version="2.0.0",
    docs_url="/docs",
)

# Include routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(songs.router)
app.include_router(playlists.router)
app.include_router(admin.router)

# Directory for static files (audio and images)
MEDIA_DIR = "media"
os.makedirs(MEDIA_DIR, exist_ok=True)

@app.get("/")
def read_root():
    return {"message": "Welcome to Beatify API v2"}

# Serve images (publicly accessible for now)
@app.get("/api/image/{filename}")
def get_image(filename: str):
    file_path = os.path.join(MEDIA_DIR, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Image file not found on server")
    return FileResponse(file_path)
