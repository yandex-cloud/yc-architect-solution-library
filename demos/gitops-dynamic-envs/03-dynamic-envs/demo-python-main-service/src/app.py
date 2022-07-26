import os
import requests

from flask import Flask, jsonify, request, abort, make_response
from flask_sqlalchemy import SQLAlchemy

from .models import User
from .config import app_config


app = Flask(__name__)
app.config.from_object(app_config[os.getenv('FLASK_ENV', 'production')])
db = SQLAlchemy(app)

@app.route('/health', methods=['GET'])
def healthcheck():
    return ('ok')

@app.route('/versions', methods=['GET'])
def get_versions():
    r = requests.get("http://{}/version".format(app.config['SERVICE_ONE']))
    return jsonify({'appOneVersion': r.json()})

@app.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    try:
        user = User.query.filter_by(id=user_id).first()
        return jsonify({'user': user.serialize})
    except Exception as e:
        abort(404)
        print(e)

@app.route('/users', methods=['POST'])
def create_user():
    if not request.json or not 'firstName' or not 'lastName' in request.json:
        abort(400)
    user = User(request.get_json()['firstName'], request.get_json()['lastName'])
    db.session.add(user)
    db.session.commit()
    return jsonify({'user': user.serialize}), 201
 
@app.errorhandler(404)
def not_found(error):
    return make_response(jsonify({'error': 'Not found'}), 404)

@app.errorhandler(400)
def not_found(error):
    return make_response(jsonify({'error': 'Bad Request'}), 400)

@app.errorhandler(405)
def not_found(error):
    return make_response(jsonify({'error': 'Method Not Allowed'}), 405)
