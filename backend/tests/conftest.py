import os
os.environ["DATABASE_URL"] = "sqlite:///./test_beatify.db"

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from main import app
from database import Base
from deps import get_db

TEST_DB_URL = "sqlite:///./test_beatify.db"
test_engine = create_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
TestSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


@pytest.fixture
def client():
    Base.metadata.drop_all(bind=test_engine)
    Base.metadata.create_all(bind=test_engine)

    def override_get_db():
        db = TestSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=test_engine)


def _register_and_login(client, email: str, username: str, password: str) -> dict:
    client.post("/api/auth/register", json={"email": email, "username": username, "password": password})
    res = client.post("/api/auth/login", data={"username": username, "password": password})
    return {"Authorization": f"Bearer {res.json()['access_token']}"}


@pytest.fixture
def admin_headers(client):
    return _register_and_login(client, "admin@test.com", "admin", "admin123")


@pytest.fixture
def user_headers(client, admin_headers):
    return _register_and_login(client, "user@test.com", "user1", "user123")


@pytest.fixture
def verified_user_headers(client, admin_headers, user_headers):
    user_id = client.get("/api/users/me", headers=user_headers).json()["id"]
    client.put(f"/api/admin/users/{user_id}/verify", headers=admin_headers)
    return user_headers
