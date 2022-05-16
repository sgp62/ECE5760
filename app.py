from flask import Flask, render_template
from flaskext.markdown import Markdown

app = Flask(__name__)
@ app.route('/')
def index():
    return render_template('index.md')

if __name__ == '__main__':
    Markdown(app)
    app.run()
