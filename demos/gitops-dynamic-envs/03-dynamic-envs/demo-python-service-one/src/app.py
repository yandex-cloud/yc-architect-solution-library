import os

from flask import Flask, jsonify, request, abort, make_response

from .config import app_config


app = Flask(__name__)
app.config.from_object(app_config[os.getenv('FLASK_ENV', 'production')])

@app.route('/health', methods=['GET'])
def healthcheck():
    return ('ok')

@app.route('/version', methods=['GET'])
def get_version():
    return jsonify({'version': app.config['APP_VERSION']})

@app.errorhandler(404)
def not_found(error):
    return make_response(jsonify({'error': 'Not found'}), 404)

@app.errorhandler(400)
def not_found(error):
    return make_response(jsonify({'error': 'Bad Request'}), 400)

@app.errorhandler(405)
def not_found(error):
    return make_response(jsonify({'error': 'Method Not Allowed'}), 405)
