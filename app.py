from flask import Flask, jsonify
import os

app = Flask(__name__)

VERSION = os.getenv("APP_VERSION", "1.0")

@app.route("/")
def home():
    return f"""
    <html>
        <head>
            <title>Automatic Rollback System</title>
        </head>
        <body>
            <h1>Automatic Rollback System</h1>
            <h2>Application Version: {VERSION}</h2>
            <p>Application is running successfully.</p>
        </body>
    </html>
    """

@app.route("/health")
def health():
    return "Application Failed", 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)