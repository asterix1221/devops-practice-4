"""Small Flask app used to demonstrate a Docker-based CI/CD pipeline."""

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify(
        message="Hello from the DevOps Practice 4 Flask app",
        status="running",
    ), 200


@app.get("/health")
def health():
    return jsonify(status="ok"), 200


if __name__ == "__main__":
    # Binding to 0.0.0.0 makes the app reachable from outside its container.
    app.run(host="0.0.0.0", port=5000)
