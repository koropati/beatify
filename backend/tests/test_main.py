import os


def test_root_endpoint(client):
    res = client.get("/")
    assert res.status_code == 200
    assert "message" in res.json()


def test_get_image_not_found(client):
    res = client.get("/api/image/does-not-exist.jpg")
    assert res.status_code == 404


def test_get_image_success(client):
    os.makedirs("media", exist_ok=True)
    path = os.path.join("media", "test_main_img.jpg")
    with open(path, "wb") as f:
        f.write(b"img-bytes")
    try:
        res = client.get("/api/image/test_main_img.jpg")
        assert res.status_code == 200
    finally:
        os.remove(path)


def test_migrate_db_adds_missing_reset_columns(tmp_path, monkeypatch):
    import main
    from sqlalchemy import create_engine, text, inspect

    db_file = tmp_path / "legacy.db"
    legacy_engine = create_engine(f"sqlite:///{db_file}")
    with legacy_engine.connect() as conn:
        conn.execute(text("CREATE TABLE users (id INTEGER PRIMARY KEY, username VARCHAR(255))"))
        conn.commit()

    monkeypatch.setattr(main, "engine", legacy_engine)
    main._migrate_db()

    cols = [c["name"] for c in inspect(legacy_engine).get_columns("users")]
    assert "reset_token" in cols
    assert "reset_token_expiry" in cols
