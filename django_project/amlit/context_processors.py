# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.conf import settings

from amlit.models import SitePreferences


def site_settings(request):
    return {
        'site_preferences': SitePreferences.load(),
    }
