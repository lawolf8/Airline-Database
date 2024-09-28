from flask import Flask, request, render_template, redirect, url_for
import pyodbc

app = Flask(__name__)

# Database connection parameters
server = 'your_server_name'
database = 'your_database_name'
username = 'your_username'
password = 'your_password'
connection_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'
cnxn = pyodbc.connect(connection_string)
cursor = cnxn.cursor()

@app.route('/')
def index():
    cursor.execute("SELECT * FROM flights")
    flights = cursor.fetchall()
    return render_template('index.html', flights=flights)

@app.route('/add', methods=['GET', 'POST'])
def add():
    if request.method == 'POST':
        date = request.form['date']
        cursor.execute("INSERT INTO flights (date) VALUES (?)", date)
        cnxn.commit()
        return redirect(url_for('index'))
    return render_template('add.html')

@app.route('/update', methods=['GET', 'POST'])
def update():
    if request.method == 'POST':
        id = request.form['id']
        date = request.form['date']
        cursor.execute("UPDATE flights SET date = ? WHERE flight_id = ?", date, id)
        cnxn.commit()
        return redirect(url_for('index'))
    return render_template('update.html')

@app.route('/delete', methods=['POST'])
def delete():
    id = request.form['id']
    cursor.execute("DELETE FROM flights WHERE flight_id = ?", id)
    cnxn.commit()
    return redirect(url_for('index'))

if __name__ == "__main__":
    app.run(debug=True)
