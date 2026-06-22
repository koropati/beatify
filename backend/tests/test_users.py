import io
import os


def test_get_me_no_auth(client):
    res = client.get("/api/users/me")
    assert res.status_code == 401


def test_get_me_returns_correct_user(client, user_headers):
    res = client.get("/api/users/me", headers=user_headers)
    assert res.status_code == 200
    data = res.json()
    assert data["username"] == "user1"
    assert data["email"] == "user@test.com"
    assert data["role"] == "user"
    assert data["is_verified"] is False


def test_get_me_admin_has_correct_role(client, admin_headers):
    res = client.get("/api/users/me", headers=admin_headers)
    assert res.status_code == 200
    data = res.json()
    assert data["role"] == "admin"
    assert data["is_verified"] is True


def test_upload_profile_picture_no_auth(client):
    res = client.post(
        "/api/users/me/picture",
        files={"file": ("pic.jpg", io.BytesIO(b"fake img"), "image/jpeg")},
    )
    assert res.status_code == 401


def test_upload_profile_picture_success(client, user_headers, sample_image_bytes):
    res = client.post(
        "/api/users/me/picture",
        files={"file": ("avatar.png", io.BytesIO(sample_image_bytes), "image/png")},
        headers=user_headers,
    )
    assert res.status_code == 200
    data = res.json()
    assert data["profile_picture_url"] is not None
    assert data["profile_picture_url"].endswith(".webp")


def test_upload_profile_picture_converts_to_webp_on_disk(client, user_headers, sample_image_bytes):
    res = client.post(
        "/api/users/me/picture",
        files={"file": ("avatar.png", io.BytesIO(sample_image_bytes), "image/png")},
        headers=user_headers,
    )
    filename = res.json()["profile_picture_url"].split("/")[-1]
    path = os.path.join("media", filename)
    assert os.path.exists(path)
    with open(path, "rb") as f:
        assert f.read(4)[:4] == b"RIFF"  # WebP container magic


def test_upload_profile_picture_replaces_old_file(client, user_headers, sample_image_bytes):
    first = client.post(
        "/api/users/me/picture",
        files={"file": ("a.png", io.BytesIO(sample_image_bytes), "image/png")},
        headers=user_headers,
    ).json()["profile_picture_url"].split("/")[-1]
    client.post(
        "/api/users/me/picture",
        files={"file": ("b.png", io.BytesIO(sample_image_bytes), "image/png")},
        headers=user_headers,
    )
    assert not os.path.exists(os.path.join("media", first))


def test_upload_palette_image_converted(client, user_headers):
    from PIL import Image
    buf = io.BytesIO()
    Image.new("P", (16, 16)).save(buf, "PNG")  # palette mode → needs conversion
    res = client.post(
        "/api/users/me/picture",
        files={"file": ("p.png", io.BytesIO(buf.getvalue()), "image/png")},
        headers=user_headers,
    )
    assert res.status_code == 200
    assert res.json()["profile_picture_url"].endswith(".webp")


def test_upload_non_image_file_rejected(client, user_headers):
    res = client.post(
        "/api/users/me/picture",
        files={"file": ("doc.pdf", io.BytesIO(b"fake pdf"), "application/pdf")},
        headers=user_headers,
    )
    assert res.status_code == 400


def test_upload_corrupt_image_rejected(client, user_headers):
    res = client.post(
        "/api/users/me/picture",
        files={"file": ("broken.png", io.BytesIO(b"not a real image"), "image/png")},
        headers=user_headers,
    )
    assert res.status_code == 400
    assert "valid image" in res.json()["detail"]


def test_update_profile_success(client, user_headers):
    res = client.put("/api/users/me", json={"username": "renamed"}, headers=user_headers)
    assert res.status_code == 200
    assert res.json()["username"] == "renamed"


def test_update_profile_with_email(client, user_headers):
    res = client.put(
        "/api/users/me",
        json={"username": "user1", "email": "newmail@test.com"},
        headers=user_headers,
    )
    assert res.status_code == 200
    assert res.json()["email"] == "newmail@test.com"


def test_update_profile_duplicate_email(client, admin_headers, user_headers):
    res = client.put(
        "/api/users/me",
        json={"username": "user1", "email": "admin@test.com"},
        headers=user_headers,
    )
    assert res.status_code == 400
    assert "already registered" in res.json()["detail"]


def test_update_profile_duplicate_username(client, admin_headers, user_headers):
    res = client.put("/api/users/me", json={"username": "admin"}, headers=user_headers)
    assert res.status_code == 400
    assert "already taken" in res.json()["detail"]


def test_change_password_success(client, user_headers):
    res = client.put(
        "/api/users/me/password",
        json={"current_password": "user123", "new_password": "newpass123"},
        headers=user_headers,
    )
    assert res.status_code == 200
    login = client.post("/api/auth/login", data={"username": "user1", "password": "newpass123"})
    assert login.status_code == 200


def test_change_password_wrong_current(client, user_headers):
    res = client.put(
        "/api/users/me/password",
        json={"current_password": "wrongpass", "new_password": "newpass123"},
        headers=user_headers,
    )
    assert res.status_code == 400
    assert "incorrect" in res.json()["detail"]
