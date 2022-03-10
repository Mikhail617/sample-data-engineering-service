from flask import Flask, request
from functools import wraps
import jwt
from aiohttp import web

app = Flask(__name__)

PUBLIC_KEY = ""


def jwt_auth(func):
    @wraps(func)
    async def wrapper(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return web.json_response(dict(error='Missing Authorization header.'), status=401)
        token = auth_header.partition(' ')[2]
        try:
            payload = jwt.decode(token, PUBLIC_KEY, algorithms='RS256')
            request.email = payload['email']
            request.warehouse_bucket = payload['warehouse_bucket']
        except jwt.exceptions.PyJWTError:
            return web.json_response(dict(error='Failed to validate token.'), status=401)
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
    print("Request test.")
    return "ok"

