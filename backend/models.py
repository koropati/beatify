from sqlalchemy import Boolean, Column, Integer, String, ForeignKey, Table, DateTime
from sqlalchemy.orm import relationship
from database import Base

# Association table for Playlist and Songs (Many-to-Many)
playlist_songs = Table(
    "playlist_songs",
    Base.metadata,
    Column("playlist_id", Integer, ForeignKey("playlists.id")),
    Column("song_id", Integer, ForeignKey("songs.id"))
)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True)
    username = Column(String(255), unique=True, index=True)
    hashed_password = Column(String(255))
    profile_picture = Column(String(255), nullable=True)
    role = Column(String(50), default="user")
    is_verified = Column(Boolean, default=False)
    reset_token = Column(String(255), nullable=True)
    reset_token_expiry = Column(DateTime, nullable=True)

    songs = relationship("Song", back_populates="owner")
    playlists = relationship("Playlist", back_populates="owner")

class Song(Base):
    __tablename__ = "songs"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), index=True)
    artist = Column(String(255), index=True)
    album = Column(String(255), index=True, nullable=True)
    duration = Column(Integer) # duration in seconds
    file_path = Column(String(255)) # path to audio file on backend
    cover_image_path = Column(String(255), nullable=True) # path to album art on backend
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=True) # Nullable for global/seed songs

    owner = relationship("User", back_populates="songs")

class Playlist(Base):
    __tablename__ = "playlists"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), index=True)
    owner_id = Column(Integer, ForeignKey("users.id"))

    owner = relationship("User", back_populates="playlists")
    songs = relationship("Song", secondary=playlist_songs)
