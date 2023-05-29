__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '05/03/21'
from django.apps import AppConfig


class Config(AppConfig):
    name = 'amlit_helpdesk'
    verbose_name = "Amlit helpdesk"

    def ready(self):
        import amlit_helpdesk.monkeypatch
