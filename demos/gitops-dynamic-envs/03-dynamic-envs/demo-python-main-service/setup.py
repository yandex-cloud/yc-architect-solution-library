from src.app import app
from src.models import db

with app.app_context():
    db.create_all()
