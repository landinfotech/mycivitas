__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '19/08/20'

from django.conf.urls import url
from django.urls import include

from amlit_helpdesk.api.ticket import (
    TicketListView,
    FeatureTicketListView,
    FeatureTicketFeatureDetailAPI)
from amlit_helpdesk.views.form_view import create_ticket

app_name = 'amlit_helpdesk'

api_url = [
    url(r'^tickets/$',
        view=TicketListView.as_view(),
        name='ticket-list'),
    url(r'^feature/(?P<id>\d+)/tickets/$',
        view=FeatureTicketListView.as_view(),
        name='feature-ticket-list'),
    url(r'^feature-ticket/(?P<id>\d+)/feature$',
        view=FeatureTicketFeatureDetailAPI.as_view(),
        name='feature-ticket-detail'),
]
urlpatterns = [
    url(r'^tickets/submit/$',
        create_ticket,
        name='submit'),
    url(r'^api/', include(api_url)),
]
