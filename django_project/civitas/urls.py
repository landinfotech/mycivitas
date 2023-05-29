# coding=utf-8
"""Project level url handler."""
from django.conf.urls import url, include
from civitas.api import (
    CommunityAPI, CommunityDetailAPI,
    FeatureGeojsonDetailAPI, ReporterDataGeojsonDetailAPI
)
from civitas.api.community import (
    CommunityCOFAPI, CommunityPOFAPI, CommunityRiskAPI,
    ReporterDataDownloadAPI, AssetDataDownloadAPI
)

from civitas.views.dashboard import (
    DashboardDetailedView, DashboardListView
)

from civitas.api.vector_tile import VectorTileApi

from amlit_helpdesk.api.ticket import CommunityTicketAPI

FEATURE_API = [
    url(r'^(?P<pk>\d+)/data',
        view=ReporterDataGeojsonDetailAPI.as_view(),
        name='feature-data'),
    url(r'^(?P<pk>\d+)',
        view=FeatureGeojsonDetailAPI.as_view(),
        name='feature-detail'),
]

DASHBOARD_API = [
    url(r'^list/',
        DashboardListView.as_view(),
        name='community-dashboard-list'),    
    url(r'^(?P<pk>\d+)/',
        DashboardDetailedView.as_view(),
        name='community-dashboard-detailed'),
]

COMMUNITY_SUMMARY_API = [
    url(r'^cof',
        CommunityCOFAPI.as_view(),
        name='community-summary-cof'),
    url(r'^pof',
        CommunityPOFAPI.as_view(),
        name='community-summary-pof'),
    url(r'^risk',
        CommunityRiskAPI.as_view(),
        name='community-summary-risk'),
    url(r'^tickets',
        CommunityTicketAPI.as_view(),
        name='community-ticket-list'),
    url(r'^reporter-data/download',
        ReporterDataDownloadAPI.as_view(),
        name='community-reporter-data-download'),
]
COMMUNITY_API = [
    url(
        r'^(?P<pk>\d+)/summary/',
        include(COMMUNITY_SUMMARY_API)
    ),
    url(r'^(?P<pk>\d+)',
        CommunityDetailAPI.as_view(),
        name='community-detail'),
    url(r'^$',
        CommunityAPI.as_view(),
        name='community'),
    
]

API = [
    # API
    url(r'^feature/', include(FEATURE_API)),
    url(r'^community/', include(COMMUNITY_API)),
    url(r'^asset-download/(?P<pk>\d+)/', AssetDataDownloadAPI.as_view(),
        name='asset-download'),
]
urlpatterns = [
    url(r'^api/', include(API)),

    url(r'^dashboard/', include(DASHBOARD_API)),

    url(
        r'^community-layer/(?P<z>\d+)/(?P<x>\d+)/(?P<y>\d+)',
        VectorTileApi.as_view(),
        name='vector-tile-layer'
    ),

]
