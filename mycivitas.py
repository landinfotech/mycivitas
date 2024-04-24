import sys
from PyQt5.QtCore import QUrl, QStringListModel 
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import (QApplication, QLineEdit, QMainWindow, 
    QPushButton, QToolBar)
from PyQt5.QtWebEngineWidgets import QWebEnginePage, QWebEngineView, QWebEngineSettings
from app import GUI
import subprocess
import threading

path_to_server = "manage.exe"

def main():

    args = "--disable-web-security"
    app = QApplication(sys.argv + [args])
    settings = QWebEngineSettings.defaultSettings()
    settings.setAttribute(QWebEngineSettings.LocalContentCanAccessRemoteUrls, True)
    gui = GUI()
    sys.exit(app.exec_())

def runserver():
    subprocess.call([path_to_server, "runserver_plus", "--noreload"], shell=True)

t = threading.Thread(name='django server', target=runserver)
t.start()

if __name__ == '__main__':
    main()