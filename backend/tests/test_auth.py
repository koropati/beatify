def test_register_first_user_becomes_admin(client):
    res = client.post("/api/auth/register", json={
        "email": "admin@test.com", "username": "admin", "password": "admin123"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["role"] == "admin"
    assert data["is_verified"] is True
    assert data["email"] == "admin@test.com"


def test_register_second_user_is_regular(client):
    client.post("/api/auth/register", json={
        "email": "admin@test.com", "username": "admin", "password": "admin123"
    })
    res = client.post("/api/auth/register", json={
        "email": "user@test.com", "username": "user1", "password": "user123"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["role"] == "user"
    assert data["is_verified"] is False


def test_register_duplicate_email(client):
    client.post("/api/auth/register", json={
        "email": "admin@test.com", "username": "admin", "password": "admin123"
    })
    res = client.post("/api/auth/register", json={
        "email": "admin@test.com", "username": "admin2", "password": "admin123"
    })
    assert res.status_code == 400
    assert "Email already registered" in res.json()["detail"]


def test_register_duplicate_username(client):
    client.post("/api/auth/register", json={
        "email": "admin@test.com", "username": "admin", "password": "admin123"
    })
    res = client.post("/api/auth/register", json={
        "email": "admin2@test.com", "username": "admin", "password": "admin123"
    })
    assert res.status_code == 400
    assert "Username already taken" in res.json()["detail"]


def test_login_success(client):
    client.post("/api/auth/register", json={
        "email": "admin@test.com", "username": "admin", "password": "admin123"
    })
    res = client.post("/api/auth/login", data={"username": "admin", "password": "admin123"})
    assert res.status_code == 200
    data = res.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_login_wrong_password(client):
    client.post("/api/auth/register", json={
        "email": "admin@test.com", "username": "admin", "password": "admin123"
    })
    res = client.post("/api/auth/login", data={"username": "admin", "password": "wrongpass"})
    assert res.status_code == 401


def test_login_nonexistent_user(client):
    res = client.post("/api/auth/login", data={"username": "nobody", "password": "pass123"})
    assert res.status_code == 401
