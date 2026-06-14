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


def test_unverified_list_includes_profile_picture_url(client, admin_headers, user_headers):
    import io
    client.post(
        "/api/users/me/picture",
        files={"file": ("a.jpg", io.BytesIO(b"img"), "image/jpeg")},
        headers=user_headers,
    )
    res = client.get("/api/admin/users/unverified", headers=admin_headers)
    user = next(u for u in res.json() if u["username"] == "user1")
    assert user["profile_picture_url"] is not None


def test_verify_user_returns_profile_picture_url(client, admin_headers, user_headers):
    import io
    client.post(
        "/api/users/me/picture",
        files={"file": ("a.jpg", io.BytesIO(b"img"), "image/jpeg")},
        headers=user_headers,
    )
    user_id = client.get("/api/users/me", headers=user_headers).json()["id"]
    res = client.put(f"/api/admin/users/{user_id}/verify", headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["profile_picture_url"] is not None
