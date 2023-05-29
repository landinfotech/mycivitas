__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '14/08/20'

from django.contrib import admin
from amlit.models import SitePreferences
from core.admin.singleton import SingletonAdmin


class SitePreferencesAdmin(SingletonAdmin):
    filter_horizontal = ('recurred_queues',)


admin.site.register(SitePreferences, SitePreferencesAdmin)
