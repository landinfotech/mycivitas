"""
This script initializes
"""

#########################################################
# Setting up the  context
#########################################################

import os
import time

import django

django.setup()

#########################################################
# Imports
#########################################################
from django.db import connection
from django.db.utils import OperationalError
from django.contrib.auth import get_user_model
from django.core.management import call_command

# Getting the secrets
admin_username = os.getenv('ADMIN_USERNAME')
admin_password = os.getenv('ADMIN_PASSWORD')
admin_email = os.getenv('ADMIN_EMAIL')

#########################################################
# 1. Waiting for PostgreSQL
#########################################################

print("-----------------------------------------------------")
print("1. Waiting for PostgreSQL")
for _ in range(60):
    try:
        connection.ensure_connection()
        break
    except OperationalError:
        time.sleep(1)
else:
    connection.ensure_connection()
connection.close()

#########################################################
# 2. Running the migrations
#########################################################

print("-----------------------------------------------------")
print("2. Running the migrations")
call_command('makemigrations')
call_command('migrate', '--noinput')

#########################################################
# 3. Creating superuser if it doesn't exist
#########################################################

print("-----------------------------------------------------")
print("3. Creating/updating superuser")
try:
    superuser = get_user_model().objects.get(email=admin_email)
    superuser.set_password(admin_password)
    superuser.is_active = True
    superuser.email = admin_email
    superuser.save()
    print('superuser successfully updated')
except get_user_model().DoesNotExist:
    superuser = get_user_model().objects.create_superuser(
        admin_email,
        admin_password
    )
    print('superuser successfully created')

#########################################################
# 4. Loading fixtures
#########################################################

print("-----------------------------------------------------")
print("4. Loading fixtures")

# Disable fixtures loading in prod by including environment variable:
import ast

_load_initial_fixtures = ast.literal_eval(
    os.getenv('INITIAL_FIXTURES', 'True'))
if _load_initial_fixtures:
    call_command('loaddata', 'amlit/fixtures.json')

#########################################################
# 5. Collecting static files
#########################################################

print("-----------------------------------------------------")
print("5. Collecting static files")
call_command('collectstatic', '--noinput', verbosity=0)



