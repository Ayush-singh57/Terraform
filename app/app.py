from flask import Flask, request, jsonify, render_template
import pymysql
import os

app = Flask(__name__)

# Database configuration (Fetched from EC2 environment variables)
DB_HOST = os.environ.get('DB_HOST')
DB_USER = os.environ.get('DB_USER')
DB_PASSWORD = os.environ.get('DB_PASSWORD')
DB_NAME = 'appdata'

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )

# Initialize the database table when the app starts
def init_db():
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS messages (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(255),
                    message TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
        connection.commit()
        connection.close()
        print("Database initialized successfully.")
    except Exception as e:
        print(f"Database connection failed: {e}")

init_db()

# Serve the HTML frontend
@app.route('/')
def index():
    return render_template('index.html')

# API to write data to the database
@app.route('/api/submit', methods=['POST'])
def submit_data():
    data = request.json
    name = data.get('name')
    message = data.get('message')
    
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            sql = "INSERT INTO messages (name, message) VALUES (%s, %s)"
            cursor.execute(sql, (name, message))
        connection.commit()
        new_id = cursor.lastrowid
        connection.close()
        return jsonify({'success': True, 'id': new_id}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# API to fetch recent data
@app.route('/api/recent', methods=['GET'])
def get_recent():
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            sql = "SELECT name, message, created_at FROM messages ORDER BY created_at DESC LIMIT 5"
            cursor.execute(sql)
            results = cursor.fetchall()
        connection.close()
        return jsonify(results), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Run on all interfaces so the ALB can route traffic to it
    app.run(host='0.0.0.0', port=5000)