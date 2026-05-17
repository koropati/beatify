import os
from database import SessionLocal, engine
import models
from core.security import get_password_hash

models.Base.metadata.create_all(bind=engine)

ADMIN_USERNAME = os.getenv("ADMIN_USERNAME", "admin")
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "admin@beatify.com")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "admin123")


def seed():
    db = SessionLocal()
    try:
        if db.query(models.User).filter(models.User.role == "admin").first():
            print("Admin already exists, skipping.")
            return

        db.add(models.User(
            email=ADMIN_EMAIL,
            username=ADMIN_USERNAME,
            hashed_password=get_password_hash(ADMIN_PASSWORD),
            role="admin",
            is_verified=True,
        ))
        db.commit()
        print(f"Admin created: {ADMIN_USERNAME} / {ADMIN_EMAIL}")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
