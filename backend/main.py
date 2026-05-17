from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import os
import models
from database import engine

# Import routers
from routers import auth, users, songs, playlists, admin

models.Base.metadata.create_all(bind=engine)

def _migrate_db():
    from sqlalchemy import text, inspect as sa_inspect
    with engine.connect() as conn:
        cols = [c['name'] for c in sa_inspect(engine).get_columns('users')]
        if 'reset_token' not in cols:
            conn.execute(text("ALTER TABLE users ADD COLUMN reset_token VARCHAR(255)"))
        if 'reset_token_expiry' not in cols:
            conn.execute(text("ALTER TABLE users ADD COLUMN reset_token_expiry DATETIME"))
        conn.commit()

_migrate_db()

app = FastAPI(
    title="Beatify API",
    description="API untuk aplikasi music streaming Beatify. Mendukung fitur autentikasi, manajemen profil, playlist, dan streaming file audio.",
    version="2.0.0",
    docs_url="/docs",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
