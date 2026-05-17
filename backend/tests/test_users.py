import io


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


def test_upload_profile_picture_success(client, user_headers):
    res = client.post(
        "/api/users/me/picture",
        files={"file": ("avatar.jpg", io.BytesIO(b"fake image content"), "image/jpeg")},
        headers=user_headers,
    )
    assert res.status_code == 200
    data = res.json()
    assert data["profile_picture_url"] is not None
    assert "http" in data["profile_picture_url"]


def test_upload_non_image_file_rejected(client, user_headers):
    res = client.post(
        "/api/users/me/picture",
        files={"file": ("doc.pdf", io.BytesIO(b"fake pdf"), "application/pdf")},
        headers=user_headers,
    )
    assert res.status_code == 400
