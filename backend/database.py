import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm import declarative_base

load_dotenv()

# MySQL Connection String Format: mysql+pymysql://user:password@host:port/database
# If environment variable is not set, fallback to a default (though it will likely fail if DB doesn't exist)
SQLALCHEMY_DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "mysql+pymysql://root:@localhost:3306/beatify_db"
)

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, 
    # pool_pre_ping=True helps handle dropped connections
    pool_pre_ping=True
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
