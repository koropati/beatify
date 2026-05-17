import io


def _upload_song(client, headers) -> int:
    res = client.post(
        "/api/songs/upload",
        data={"title": "Test Song", "artist": "Test Artist"},
        files={"audio_file": ("song.mp3", io.BytesIO(b"fake mp3"), "audio/mpeg")},
        headers=headers,
    )
    return res.json()["id"]


def test_get_playlists_no_auth(client):
    res = client.get("/api/playlists")
    assert res.status_code == 401


def test_get_playlists_empty(client, user_headers):
    res = client.get("/api/playlists", headers=user_headers)
    assert res.status_code == 200
    assert res.json() == []


def test_create_playlist(client, user_headers):
    res = client.post("/api/playlists", json={"name": "Chill Vibes"}, headers=user_headers)
    assert res.status_code == 200
    data = res.json()
    assert data["name"] == "Chill Vibes"
    assert data["songs"] == []
    assert "id" in data


def test_create_multiple_playlists(client, user_headers):
    client.post("/api/playlists", json={"name": "Playlist 1"}, headers=user_headers)
    client.post("/api/playlists", json={"name": "Playlist 2"}, headers=user_headers)
    res = client.get("/api/playlists", headers=user_headers)
    assert res.status_code == 200
    assert len(res.json()) == 2


def test_add_song_to_playlist(client, admin_headers, user_headers):
    playlist_id = client.post("/api/playlists", json={"name": "My Mix"}, headers=user_headers).json()["id"]
    song_id = _upload_song(client, admin_headers)

    res = client.post(f"/api/playlists/{playlist_id}/songs/{song_id}", headers=user_headers)
    assert res.status_code == 200
    songs = res.json()["songs"]
    assert len(songs) == 1
    assert songs[0]["id"] == song_id


def test_add_duplicate_song_to_playlist(client, admin_headers, user_headers):
    playlist_id = client.post("/api/playlists", json={"name": "My Mix"}, headers=user_headers).json()["id"]
    song_id = _upload_song(client, admin_headers)

    client.post(f"/api/playlists/{playlist_id}/songs/{song_id}", headers=user_headers)
    res = client.post(f"/api/playlists/{playlist_id}/songs/{song_id}", headers=user_headers)
    assert res.status_code == 400
    assert "already in playlist" in res.json()["detail"]


def test_add_song_to_nonexistent_playlist(client, admin_headers, user_headers):
    song_id = _upload_song(client, admin_headers)
    res = client.post(f"/api/playlists/9999/songs/{song_id}", headers=user_headers)
    assert res.status_code == 404


def test_add_nonexistent_song_to_playlist(client, user_headers):
    playlist_id = client.post("/api/playlists", json={"name": "My Mix"}, headers=user_headers).json()["id"]
    res = client.post(f"/api/playlists/{playlist_id}/songs/9999", headers=user_headers)
    assert res.status_code == 404


def test_playlist_only_shows_owner_playlists(client, admin_headers, user_headers):
    client.post("/api/playlists", json={"name": "Admin Playlist"}, headers=admin_headers)
    client.post("/api/playlists", json={"name": "User Playlist"}, headers=user_headers)

    user_playlists = client.get("/api/playlists", headers=user_headers).json()
    assert len(user_playlists) == 1
    assert user_playlists[0]["name"] == "User Playlist"


def test_add_song_to_other_users_playlist_forbidden(client, admin_headers, user_headers):
    admin_playlist_id = client.post("/api/playlists", json={"name": "Admin Playlist"}, headers=admin_headers).json()["id"]
    song_id = _upload_song(client, admin_headers)

    res = client.post(f"/api/playlists/{admin_playlist_id}/songs/{song_id}", headers=user_headers)
    assert res.status_code == 404
