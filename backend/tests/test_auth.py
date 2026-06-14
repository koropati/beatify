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


# --- Forgot / Reset Password ---

def test_forgot_password_existing_user(client):
    client.post("/api/auth/register", json={
        "email": "u@test.com", "username": "u", "password": "pass123"
    })
    res = client.post("/api/auth/forgot-password", json={"email": "u@test.com"})
    assert res.status_code == 200
    assert res.json()["token"] is not None


def test_forgot_password_nonexistent_user(client):
    res = client.post("/api/auth/forgot-password", json={"email": "ghost@test.com"})
    assert res.status_code == 200
    assert res.json()["token"] is None


def test_reset_password_success(client):
    client.post("/api/auth/register", json={
        "email": "u@test.com", "username": "u", "password": "pass123"
    })
    token = client.post("/api/auth/forgot-password", json={"email": "u@test.com"}).json()["token"]
    res = client.post("/api/auth/reset-password", json={"token": token, "new_password": "brandnew123"})
    assert res.status_code == 200
    login = client.post("/api/auth/login", data={"username": "u", "password": "brandnew123"})
    assert login.status_code == 200


def test_reset_password_invalid_token(client):
    res = client.post("/api/auth/reset-password", json={"token": "999999", "new_password": "x123456"})
    assert res.status_code == 400
    assert "Invalid" in res.json()["detail"]


def test_reset_password_expired_token(client):
    from datetime import datetime, timedelta
    from tests.conftest import TestSessionLocal
    from models import User

    client.post("/api/auth/register", json={
        "email": "u@test.com", "username": "u", "password": "pass123"
    })
    token = client.post("/api/auth/forgot-password", json={"email": "u@test.com"}).json()["token"]

    db = TestSessionLocal()
    user = db.query(User).filter(User.username == "u").first()
    user.reset_token_expiry = datetime.utcnow() - timedelta(minutes=1)
    db.commit()
    db.close()

    res = client.post("/api/auth/reset-password", json={"token": token, "new_password": "x123456"})
    assert res.status_code == 400
    assert "expired" in res.json()["detail"]


# --- Auth dependency: token validation (deps.py) ---

def test_request_with_token_missing_sub(client):
    from core.security import create_access_token
    token = create_access_token({"foo": "bar"})
    res = client.get("/api/users/me", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 401


def test_request_with_invalid_token(client):
    res = client.get("/api/users/me", headers={"Authorization": "Bearer not-a-valid-token"})
    assert res.status_code == 401


def test_request_with_token_for_unknown_user(client):
    from core.security import create_access_token
    token = create_access_token({"sub": "ghostuser"})
    res = client.get("/api/users/me", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 401


def test_get_db_dependency_yields_and_closes():
    from deps import get_db
    gen = get_db()
    db = next(gen)
    assert db is not None
    gen.close()  # triggers the finally/close branch


# --- Security primitives (core/security.py) ---

def test_verify_password_invalid_hash_returns_false():
    from core.security import verify_password
    assert verify_password("whatever", "not-a-bcrypt-hash") is False


def test_password_hash_and_verify_roundtrip():
    from core.security import get_password_hash, verify_password
    h = get_password_hash("s3cret")
    assert verify_password("s3cret", h) is True
    assert verify_password("wrong", h) is False


def test_create_access_token_default_expiry():
    from core.security import create_access_token, SECRET_KEY, ALGORITHM
    from jose import jwt
    token = create_access_token({"sub": "x"})
    payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    assert payload["sub"] == "x"
    assert "exp" in payload
