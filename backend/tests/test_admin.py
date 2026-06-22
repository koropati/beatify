def test_get_unverified_no_auth(client):
    res = client.get("/api/admin/users/unverified")
    assert res.status_code == 401


def test_get_unverified_non_admin_forbidden(client, user_headers):
    res = client.get("/api/admin/users/unverified", headers=user_headers)
    assert res.status_code == 403


def test_get_unverified_as_admin(client, admin_headers, user_headers):
    res = client.get("/api/admin/users/unverified", headers=admin_headers)
    assert res.status_code == 200
    users = res.json()
    usernames = [u["username"] for u in users]
    assert "user1" in usernames
    assert "admin" not in usernames


def test_verify_user_success(client, admin_headers, user_headers):
    user_id = client.get("/api/users/me", headers=user_headers).json()["id"]
    res = client.put(f"/api/admin/users/{user_id}/verify", headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["is_verified"] is True


def test_verify_user_disappears_from_unverified_list(client, admin_headers, user_headers):
    user_id = client.get("/api/users/me", headers=user_headers).json()["id"]
    client.put(f"/api/admin/users/{user_id}/verify", headers=admin_headers)

    res = client.get("/api/admin/users/unverified", headers=admin_headers)
    usernames = [u["username"] for u in res.json()]
    assert "user1" not in usernames


def test_verify_already_verified_user(client, admin_headers, user_headers):
    user_id = client.get("/api/users/me", headers=user_headers).json()["id"]
    client.put(f"/api/admin/users/{user_id}/verify", headers=admin_headers)

    res = client.put(f"/api/admin/users/{user_id}/verify", headers=admin_headers)
    assert res.status_code == 400
    assert "already verified" in res.json()["detail"]


def test_verify_nonexistent_user(client, admin_headers):
    res = client.put("/api/admin/users/9999/verify", headers=admin_headers)
    assert res.status_code == 404


def test_verify_by_non_admin_forbidden(client, admin_headers, user_headers):
    user_id = client.get("/api/users/me", headers=user_headers).json()["id"]
    res = client.put(f"/api/admin/users/{user_id}/verify", headers=user_headers)
    assert res.status_code == 403


def test_unverified_list_includes_profile_picture_url(client, admin_headers, user_headers, sample_image_bytes):
    import io
    client.post(
        "/api/users/me/picture",
        files={"file": ("a.png", io.BytesIO(sample_image_bytes), "image/png")},
        headers=user_headers,
    )
    res = client.get("/api/admin/users/unverified", headers=admin_headers)
    user = next(u for u in res.json() if u["username"] == "user1")
    assert user["profile_picture_url"] is not None


def test_verify_user_returns_profile_picture_url(client, admin_headers, user_headers, sample_image_bytes):
    import io
    client.post(
        "/api/users/me/picture",
        files={"file": ("a.png", io.BytesIO(sample_image_bytes), "image/png")},
        headers=user_headers,
    )
    user_id = client.get("/api/users/me", headers=user_headers).json()["id"]
    res = client.put(f"/api/admin/users/{user_id}/verify", headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["profile_picture_url"] is not None


# --- Admin: list & update users ---

def test_list_users_no_auth(client):
    res = client.get("/api/admin/users")
    assert res.status_code == 401


def test_list_users_non_admin_forbidden(client, user_headers):
    res = client.get("/api/admin/users", headers=user_headers)
    assert res.status_code == 403


def test_list_users_as_admin(client, admin_headers, user_headers):
    res = client.get("/api/admin/users", headers=admin_headers)
    assert res.status_code == 200
    usernames = [u["username"] for u in res.json()]
    assert "admin" in usernames
    assert "user1" in usernames


def test_update_user_username_and_email(client, admin_headers, user_headers):
    user_id = client.get("/api/users/me", headers=user_headers).json()["id"]
    res = client.put(
        f"/api/admin/users/{user_id}",
        json={"username": "edited", "email": "edited@test.com"},
        headers=admin_headers,
    )
    assert res.status_code == 200
    data = res.json()
    assert data["username"] == "edited"
    assert data["email"] == "edited@test.com"


def test_update_user_role_and_verified(client, admin_headers, user_headers):
    user_id = client.get("/api/users/me", headers=user_headers).json()["id"]
    res = client.put(
        f"/api/admin/users/{user_id}",
        json={"role": "admin", "is_verified": True},
        headers=admin_headers,
    )
    assert res.status_code == 200
    assert res.json()["role"] == "admin"
    assert res.json()["is_verified"] is True


def test_update_user_invalid_role(client, admin_headers, user_headers):
    user_id = client.get("/api/users/me", headers=user_headers).json()["id"]
    res = client.put(
        f"/api/admin/users/{user_id}",
        json={"role": "superuser"},
        headers=admin_headers,
    )
    assert res.status_code == 400
    assert "Invalid role" in res.json()["detail"]


def test_update_user_duplicate_username(client, admin_headers, user_headers):
    user_id = client.get("/api/users/me", headers=user_headers).json()["id"]
    res = client.put(
        f"/api/admin/users/{user_id}",
        json={"username": "admin"},
        headers=admin_headers,
    )
    assert res.status_code == 400
    assert "already taken" in res.json()["detail"]


def test_update_user_duplicate_email(client, admin_headers, user_headers):
    user_id = client.get("/api/users/me", headers=user_headers).json()["id"]
    res = client.put(
        f"/api/admin/users/{user_id}",
        json={"email": "admin@test.com"},
        headers=admin_headers,
    )
    assert res.status_code == 400
    assert "already registered" in res.json()["detail"]


def test_update_user_nonexistent(client, admin_headers):
    res = client.put("/api/admin/users/9999", json={"username": "x"}, headers=admin_headers)
    assert res.status_code == 404


def test_update_user_non_admin_forbidden(client, user_headers):
    res = client.put("/api/admin/users/1", json={"username": "x"}, headers=user_headers)
    assert res.status_code == 403


# --- Admin: manage public songs ---

def _upload_song(client, headers, title="Song", artist="Artist"):
    import io
    return client.post(
        "/api/songs/upload",
        data={"title": title, "artist": artist},
        files={"audio_file": ("s.mp3", io.BytesIO(b"fake mp3"), "audio/mpeg")},
        headers=headers,
    ).json()["id"]


def test_list_all_songs_as_admin(client, admin_headers):
    _upload_song(client, admin_headers, title="Track A")
    res = client.get("/api/admin/songs", headers=admin_headers)
    assert res.status_code == 200
    assert len(res.json()) == 1
    assert res.json()[0]["title"] == "Track A"


def test_list_all_songs_non_admin_forbidden(client, user_headers):
    res = client.get("/api/admin/songs", headers=user_headers)
    assert res.status_code == 403


def test_update_song_metadata(client, admin_headers):
    song_id = _upload_song(client, admin_headers)
    res = client.put(
        f"/api/admin/songs/{song_id}",
        json={"title": "New Title", "artist": "New Artist", "album": "New Album"},
        headers=admin_headers,
    )
    assert res.status_code == 200
    data = res.json()
    assert data["title"] == "New Title"
    assert data["artist"] == "New Artist"
    assert data["album"] == "New Album"


def test_update_song_nonexistent(client, admin_headers):
    res = client.put("/api/admin/songs/9999", json={"title": "x"}, headers=admin_headers)
    assert res.status_code == 404


def test_update_song_non_admin_forbidden(client, user_headers):
    res = client.put("/api/admin/songs/1", json={"title": "x"}, headers=user_headers)
    assert res.status_code == 403


def test_delete_song_success(client, admin_headers):
    song_id = _upload_song(client, admin_headers)
    res = client.delete(f"/api/admin/songs/{song_id}", headers=admin_headers)
    assert res.status_code == 200
    assert "deleted" in res.json()["message"]
    assert client.get("/api/admin/songs", headers=admin_headers).json() == []


def test_delete_song_removes_files(client, admin_headers, sample_image_bytes):
    import io
    import os
    upload = client.post(
        "/api/songs/upload",
        data={"title": "WithCover", "artist": "A"},
        files={
            "audio_file": ("s.mp3", io.BytesIO(b"fake mp3"), "audio/mpeg"),
            "cover_image": ("c.png", io.BytesIO(sample_image_bytes), "image/png"),
        },
        headers=admin_headers,
    ).json()
    from tests.conftest import TestSessionLocal
    from models import Song
    db = TestSessionLocal()
    song = db.query(Song).filter(Song.id == upload["id"]).first()
    audio_path = os.path.join("media", song.file_path)
    cover_path = os.path.join("media", song.cover_image_path)
    db.close()
    assert os.path.exists(audio_path)

    client.delete(f"/api/admin/songs/{upload['id']}", headers=admin_headers)
    assert not os.path.exists(audio_path)
    assert not os.path.exists(cover_path)


def test_delete_song_detaches_from_playlist(client, admin_headers):
    song_id = _upload_song(client, admin_headers)
    playlist = client.post(
        "/api/playlists", json={"name": "P"}, headers=admin_headers
    ).json()
    client.post(
        f"/api/playlists/{playlist['id']}/songs/{song_id}", headers=admin_headers
    )
    res = client.delete(f"/api/admin/songs/{song_id}", headers=admin_headers)
    assert res.status_code == 200


def test_delete_song_nonexistent(client, admin_headers):
    res = client.delete("/api/admin/songs/9999", headers=admin_headers)
    assert res.status_code == 404


def test_delete_song_non_admin_forbidden(client, user_headers):
    res = client.delete("/api/admin/songs/1", headers=user_headers)
    assert res.status_code == 403
