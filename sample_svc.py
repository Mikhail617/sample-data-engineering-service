from flask import Flask, request
from functools import wraps
import jwt
from aiohttp import web
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.DEBUG)

PUBLIC_KEY = ""


def jwt_auth(func):
    @wraps(func)
    async def wrapper(*args, **kwargs):
        app.logger.debug("JWT_authentication start:")
        auth_header = request.headers.get('Authorization')
        app.logger.debug("auth_header: {}".format(auth_header))
        if not auth_header:
            return web.json_response(dict(error='Missing Authorization header.'), status=401)
        token = auth_header.partition(' ')[2]
        app.logger.debug("token: {}".format(token))
        try:
            payload = jwt.decode(token, PUBLIC_KEY, algorithms='RS256')
            app.logger.debug("payload: {}".format(payload))
            request.email = payload['email']
            request.warehouse_bucket = payload['warehouse_bucket']
        except jwt.exceptions.PyJWTError:
            return web.json_response(dict(error='Failed to validate token.'), status=401)
        app.logger.debug("request: {}".format(request))
        return await func(request, *args, **kwargs)
    return wrapper


@app.route('/')
#@jwt_auth
def health_check():
    """
    Serves as the health-check for AWS ECS target group and a test point for dev
    """
    return "Sample Data Engineering Service!"


@app.route('/process')
@jwt_auth
def process_request(request):
    """
    Process request
    """
    app.logger.info("Processing a sample request...")
    return "ok"

