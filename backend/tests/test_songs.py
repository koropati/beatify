import io


def _fake_mp3() -> tuple:
    return ("song.mp3", io.BytesIO(b"fake mp3 content"), "audio/mpeg")


def test_list_songs_public_no_auth_required(client):
    res = client.get("/api/songs")
    assert res.status_code == 200
    assert res.json() == []


def test_list_songs_with_pagination_params(client):
    res = client.get("/api/songs?skip=0&limit=5")
    assert res.status_code == 200
    assert isinstance(res.json(), list)


def test_upload_song_no_auth(client):
    res = client.post(
        "/api/songs/upload",
        data={"title": "Test", "artist": "Test"},
        files={"audio_file": _fake_mp3()},
    )
    assert res.status_code == 401


def test_upload_song_unverified_user_forbidden(client, user_headers):
    res = client.post(
        "/api/songs/upload",
        data={"title": "Test", "artist": "Test"},
        files={"audio_file": _fake_mp3()},
        headers=user_headers,
    )
    assert res.status_code == 403


def test_upload_song_as_admin_success(client, admin_headers):
    res = client.post(
        "/api/songs/upload",
        data={"title": "Bohemian Rhapsody", "artist": "Queen", "album": "A Night at the Opera"},
        files={"audio_file": _fake_mp3()},
        headers=admin_headers,
    )
    assert res.status_code == 200
    data = res.json()
    assert data["title"] == "Bohemian Rhapsody"
    assert data["artist"] == "Queen"
    assert data["album"] == "A Night at the Opera"
    assert "id" in data
    assert data["file_url"] is not None


def test_upload_song_as_verified_user_success(client, verified_user_headers):
    res = client.post(
        "/api/songs/upload",
        data={"title": "Verified Track", "artist": "Artist"},
        files={"audio_file": _fake_mp3()},
        headers=verified_user_headers,
    )
    assert res.status_code == 200
    assert res.json()["title"] == "Verified Track"


def test_upload_non_mp3_rejected(client, admin_headers):
    res = client.post(
        "/api/songs/upload",
        data={"title": "Test", "artist": "Test"},
        files={"audio_file": ("song.wav", io.BytesIO(b"fake wav"), "audio/wav")},
        headers=admin_headers,
    )
    assert res.status_code == 400


def test_list_songs_after_upload(client, admin_headers):
    client.post(
        "/api/songs/upload",
        data={"title": "Track A", "artist": "Artist A"},
        files={"audio_file": _fake_mp3()},
        headers=admin_headers,
    )
    res = client.get("/api/songs")
    assert res.status_code == 200
    songs = res.json()
    assert len(songs) == 1
    assert songs[0]["title"] == "Track A"
    assert songs[0]["file_url"] is not None


def test_stream_song_not_found(client):
    res = client.get("/api/songs/stream/9999")
    assert res.status_code == 404


def test_upload_song_with_cover_image(client, admin_headers):
    res = client.post(
        "/api/songs/upload",
        data={"title": "Covered", "artist": "Artist"},
        files={
            "audio_file": _fake_mp3(),
            "cover_image": ("cover.jpg", io.BytesIO(b"fake cover"), "image/jpeg"),
        },
        headers=admin_headers,
    )
    assert res.status_code == 200
    assert res.json()["cover_image_url"] is not None


def test_upload_song_extracts_duration(client, admin_headers, monkeypatch):
    import routers.songs as songs_router

    class _FakeInfo:
        length = 200.7

    class _FakeMP3:
        def __init__(self, path):
            self.info = _FakeInfo()

    monkeypatch.setattr(songs_router, "MP3", _FakeMP3)
    res = client.post(
        "/api/songs/upload",
        data={"title": "Timed", "artist": "Artist"},
        files={"audio_file": _fake_mp3()},
        headers=admin_headers,
    )
    assert res.status_code == 200
    assert res.json()["duration"] == 200


def test_stream_song_success(client, admin_headers):
    song_id = client.post(
        "/api/songs/upload",
        data={"title": "Playable", "artist": "Artist"},
        files={"audio_file": _fake_mp3()},
        headers=admin_headers,
    ).json()["id"]

    res = client.get(f"/api/songs/stream/{song_id}")
    assert res.status_code == 200
    assert res.headers["content-type"] == "audio/mpeg"


def test_stream_song_file_missing(client, admin_headers):
    upload = client.post(
        "/api/songs/upload",
        data={"title": "Ghost", "artist": "Nobody"},
        files={"audio_file": _fake_mp3()},
        headers=admin_headers,
    )
    song_id = upload.json()["id"]

    import os
    from tests.conftest import TestSessionLocal
    db = TestSessionLocal()
    from models import Song
    song = db.query(Song).filter(Song.id == song_id).first()
    os.remove(os.path.join("media", song.file_path))
    db.close()

    res = client.get(f"/api/songs/stream/{song_id}")
    assert res.status_code == 404
