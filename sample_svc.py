from flask import Flask

app = Flask(__name__)


@app.route('/')
def health_check():
    """
    Serves as the health-check for AWS ECS target group and a test point for dev
    """
    return "Sample Data Engineering Service!"

