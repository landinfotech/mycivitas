import sys
from PyQt5.QtCore import QUrl
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import (QApplication, QLineEdit, QMainWindow, 
    QPushButton, QToolBar)
from PyQt5.QtWebEngineWidgets import QWebEnginePage, QWebEngineView, QWebEngineSettings

class GUI(QMainWindow):
    
    def __init__(self):
        super(GUI, self).__init__()
        self.initUI()

    def initUI(self):
        self.webEngineView = QWebEngineView(self)
        self.setCentralWidget(self.webEngineView)
        self.webEngineView.load(QUrl('http://127.0.0.1:8000'))

        self.setWindowTitle('My Civitas')
        self.showMaximized()
        self.show()

    def load(self):
        url = QUrl('http://127.0.0.1:8000')
        if url.isValid():
            self.webEngineView.load(url)