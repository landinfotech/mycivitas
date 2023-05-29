# coding=utf-8

"""Project level settings."""
from .project import *  # noqa

# Comment if you are not running behind proxy
USE_X_FORWARDED_HOST = True

# -------------------------------------------------- #
# ----------            EMAIL           ------------ #
# -------------------------------------------------- #
# See fig.yml file for postfix container definition#
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
# Host for sending e-mail.
EMAIL_HOST = os.environ.get('EMAIL_HOST', 'smtp')
# Port for sending e-mail.
EMAIL_PORT = ast.literal_eval(os.environ.get('EMAIL_PORT', '25'))
# SMTP authentication information for EMAIL_HOST.
# See fig.yml for where these are defined
EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER', 'noreply@kartoza.com')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', 'docker')
EMAIL_USE_TLS = ast.literal_eval(os.environ.get('EMAIL_USE_TLS', 'False'))
EMAIL_USE_SSL = ast.literal_eval(os.environ.get('EMAIL_USE_SSL', 'False'))
EMAIL_SUBJECT_PREFIX = os.environ.get('EMAIL_SUBJECT_PREFIX', '[MyCivitas.ca]')

SERVER_EMAIL = os.environ.get('ADMIN_EMAIL', 'noreply@kartoza.com')
DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL', 'noreply@kartoza.com')

# -------------------------------------------------- #
# ----------            CELERY          ------------ #
# -------------------------------------------------- #
CELERY_BROKER_URL = 'amqp://guest:guest@%s:5672//' % os.environ.get('RABBITMQ_HOST', 'rabbitmq')
CELERY_RESULT_BACKEND = None
CELERY_TASK_ALWAYS_EAGER = True  # set this to False in order to run async
CELERY_TASK_IGNORE_RESULT = True
CELERY_TASK_DEFAULT_QUEUE = "default"
CELERY_TASK_DEFAULT_EXCHANGE = "default"
CELERY_TASK_DEFAULT_EXCHANGE_TYPE = "direct"
CELERY_TASK_DEFAULT_ROUTING_KEY = "default"
CELERY_TASK_CREATE_MISSING_QUEUES = True
CELERY_TASK_RESULT_EXPIRES = 1
CELERY_WORKER_DISABLE_RATE_LIMITS = True
CELERY_WORKER_SEND_TASK_EVENTS = False
