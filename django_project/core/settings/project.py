# coding=utf-8

"""Project level settings.
Adjust these values as needed but don't commit passwords etc. to any public
repository!
"""
import ast
import os
import sys  # noqa
from django.utils.translation import ugettext_lazy as _
from .base import *  # noqa

DEBUG = True

dirname = os.path.dirname(__file__)
db_file = os.path.join(dirname, "db.txt")

DJANGO_USER = ""
DJANGO_PSW = ""
DJANGO_DB = ""
CIVITAS_USER = ""
CIVITAS_PSW = ""
CIVITAS_DB = ""

with open(db_file) as f:
    for line in f.readlines():

        if line.split("=")[0] == "DJANGO_USER":
            DJANGO_USER = line.split("=")[1].strip()
        elif line.split("=")[0] == "DJANGO_PSW":
            DJANGO_PSW = line.split("=")[1].strip()
        elif line.split("=")[0] == "CIVITAS_USER":
            CIVITAS_USER = line.split("=")[1].strip()
        elif line.split("=")[0] == "CIVITAS_PSW":
            CIVITAS_PSW = line.split("=")[1].strip()
        elif line.split("=")[0] == "DJANGO_DB":
            DJANGO_DB = line.split("=")[1].strip()
        elif line.split("=")[0] == "CIVITAS_DB":
            CIVITAS_DB = line.split("=")[1].strip()

SECRET_KEY = os.environ.get('SECRET_KEY', 'SECRET KEY')

# Extra installed apps

sys.modules['web_app'] = __import__('web-app')

INSTALLED_APPS = INSTALLED_APPS + (
    # 3rd party
    'rest_framework',
    'rest_framework_gis',
    'sass_processor',

    # apps
    'core',
    'amlit',
    'civitas',
    'web_app',

    # helpdesk
    'bootstrap4form',

    'account',  # Required by pinax-teams
    'pinax.invitations',  # required by pinax-teams
    'pinax.teams',  # team support
    'helpdesk',  # This is us!
    'reversion',  # required by pinax-teams

    'amlit_helpdesk',  # this is customized helpdesk for amlit

    # stripe
    'djstripe',  # for subscription with stripe
)

CORS_ORIGIN_ALLOW_ALL = True
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_HEADERS = ["*"]
ALLOWED_HOSTS = ['*']

SASS_PROCESSOR_ROOT = STATIC_ROOT
STATICFILES_FINDERS += ('sass_processor.finders.CssFinder',)

# databases
# DATABASES = {
#     'default': {
#         'ENGINE': 'django.contrib.gis.db.backends.postgis',
#         'NAME': os.environ['DATABASE_NAME'],
#         'USER': os.environ['DATABASE_USERNAME'],
#         'PASSWORD': os.environ['DATABASE_PASSWORD'],
#         'HOST': os.environ['DATABASE_HOST'],
#         'PORT': 5432,
#         'TEST_NAME': 'unittests',
#     }
# }

DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': DJANGO_DB,
        'USER': DJANGO_USER,
        'PASSWORD': DJANGO_PSW,
        'HOST': 'localhost',
        'PORT': 5432,
        'TEST_NAME': 'unittests',
    }
}

# Admins and allowed hosts
ADMINS = (
    ('Irwan Fathurrahman', 'meomancer@gmail.com'),
)

# Set languages which want to be translated
# LANGUAGES = (
#     ('en', _('English')),
# )


# -------------------------------------------------- #
# ----------      CIVITAS database      ------------ #
# -------------------------------------------------- #
CIVITAS_DATABASE = 'civitas'
# DATABASES[CIVITAS_DATABASE] = {
#     'ENGINE': 'django.contrib.gis.db.backends.postgis',
#     'NAME': os.environ['DATABASE_CIVITAS_NAME'],
#     'USER': os.environ['DATABASE_CIVITAS_USERNAME'],
#     'PASSWORD': os.environ['DATABASE_CIVITAS_PASSWORD'],
#     'HOST': os.environ['DATABASE_CIVITAS_HOST'],
#     'PORT': os.environ['DATABASE_CIVITAS_PORT'],
#     'OPTIONS': {'sslmode': 'require'},
#     'TEST_NAME': 'unittests',
# }

DATABASES[CIVITAS_DATABASE] = {
    'ENGINE': 'django.contrib.gis.db.backends.postgis',
    'NAME': CIVITAS_DB,
    'USER': CIVITAS_USER,
    'PASSWORD': CIVITAS_PSW,
    'HOST': 'localhost',
    'PORT': 5432,
    'TEST_NAME': 'unittests',
}

DATABASE_ROUTERS = ['civitas.router.Router']

# -------------------------------------------------- #
# ----------    Custom ADMIN Section    ------------ #
# -------------------------------------------------- #
# Create APP as the key, after that group it by it's model
ADMIN_GROUP = {
    'amlit': {
        'Preferences': [
            'SitePreferences'
        ],
        'Authentication and authorization': [
            'User',
            'UserTitle'
        ],
        'Organisation': [
            'Organisation',
            'UserOrganisation',
            'UserRole',
            'RolePermission'
        ]
    },
    'amlit_helpdesk': {
        'Tickets': [
            'FeatureTicket',
            'RecurringTicket'
        ],
        'Scheduler': [
            'SchedulerTemplate',
            'SchedulerOrganisation'
        ]
    },
    'civitas': {
        'config': [
            'Unit',
            'Condition',
            'Deterioration'
        ],
        'risk': [
            'POF',
            'COF',
            'Risk'
        ],
        'feature identifier': [
            'FeatureClass',
            'FeatureSubClass',
            'FeatureType',
            'FeatureSubType',
            'FeatureTypeCombination'
        ],
        'community': [
            'Province', 'Region', 'Community', 'CapitalProject', 'CivicAddress'
        ],
        'feature': [
            'System',
            'FeatureBase',
            'FeatureGeometry'
        ],
        'view': [
            'ReporterData'
        ]
    }
}
AUTH_USER_MODEL = 'amlit.User'

# -------------------------------------------------- #
# ----------      Helpdesk settings     ------------ #
# -------------------------------------------------- #
HELPDESK_KB_ENABLED = False
HELPDESK_ALLOW_NON_STAFF_TICKET_UPDATE = True

# -------------------------------------------------- #
# ----------       Subscription      ------------ #
# -------------------------------------------------- #
ENABLE_SUBSCRIPTION = ast.literal_eval(
    os.environ.get(
        'ENABLE_SUBSCRIPTION', 'False'))  # Change to True to use subscription

# -------------------------------------------------- #
# ----------       DJ Stripe setup      ------------ #
# -------------------------------------------------- #
STRIPE_LIVE_PUBLIC_KEY = os.environ.get("STRIPE_LIVE_PUBLIC_KEY", "")
STRIPE_LIVE_SECRET_KEY = os.environ.get("STRIPE_LIVE_SECRET_KEY", "sk_live_")
STRIPE_TEST_PUBLIC_KEY = os.environ.get("STRIPE_TEST_PUBLIC_KEY", "")
STRIPE_TEST_SECRET_KEY = os.environ.get("STRIPE_TEST_SECRET_KEY", "sk_test_")
STRIPE_LIVE_MODE = ast.literal_eval(
    os.environ.get(
        'STRIPE_LIVE_MODE', 'False'))  # Change to True in production
DJSTRIPE_PRORATION_POLICY = True

# Get it from the section in the Stripe dashboard where you added the
# webhook endpoint
DJSTRIPE_WEBHOOK_SECRET = os.environ.get('DJSTRIPE_WEBHOOK_SECRET', 'whsec_x')
DJSTRIPE_FOREIGN_KEY_TO_FIELD = "id"

