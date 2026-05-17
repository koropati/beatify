import sys
import os
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
os.chdir(str(Path(__file__).parent))

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

from main import app as asgi_app
from a2wsgi import ASGIMiddleware

application = ASGIMiddleware(asgi_app)
