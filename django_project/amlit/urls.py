__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '19/08/20'

from django.conf.urls import url, include
from amlit.views.home import HomeView
from amlit.views.invitation import (
    UserOrganisationInvitationLogin,
    UserOrganisationInvitationSignup,
    UserOrganisationInvitationPage
)
from amlit.views.map import MapView
from amlit.views.organisations import (
    OrganisationDetailView,
    OrganisationListView,
    SubscriptionView,
    SubscriptionChangeView,
    SubscriptionCompleteView,
    SignupCompleteView,
)
from amlit.views.signup import SignUpView, SignUpSubscriptionView
from amlit.views.user import (
    UserDetailView, UserSettingsView
)
from amlit.api import (
    OrganisationAvailableUserSearch,
    OrganisationCreateScheduler,
    OrganisationEditScheduler,
    OrganisationInvitation,
    OrganisationSchedulerActivate,
    OrganisationSchedulerInactivate,
    OrganisationSchedulerList,
    UserOrganisationDetail,
    UserOrganisationInvitationAccept,
    UserOrganisationInvitationDetail,
    UserOrganisationInvitationReject,
)

ORGANISATION_SCHEDULER = [
    url(r'^create',
        OrganisationCreateScheduler.as_view(),
        name='organisation_schedule_create'),
    url(r'^(?P<schedule_pk>\d+)/edit',
        OrganisationEditScheduler.as_view(),
        name='organisation_schedule_edit'),
    url(r'^(?P<schedule_pk>\d+)/activate',
        OrganisationSchedulerActivate.as_view(),
        name='organisation_schedule_activate'),
    url(r'^(?P<schedule_pk>\d+)/inactive',
        OrganisationSchedulerInactivate.as_view(),
        name='organisation_schedule_inactivate'),
    url(r'^$',
        OrganisationSchedulerList.as_view(),
        name='organisation_scheduler_list'),
]
ORGANISATION_URL = [
    url(r'^signup/complete',
        SignupCompleteView.as_view(),
        name='organisation_signup_complete'),
    url(r'^subscription/complete',
        SubscriptionCompleteView.as_view(),
        name='organisation_subscription_complete'),
    url(r'^subscription/change',
        SubscriptionChangeView.as_view(),
        name='organisation_subscription_change'),
    url(r'^subscription',
        SubscriptionView.as_view(),
        name='organisation_subscription'),
    url(r'^available-user',
        OrganisationAvailableUserSearch.as_view(),
        name='organisation_available_user'),
    url(r'^invite-user',
        OrganisationInvitation.as_view(),
        name='organisation_invite_user'),
    url(r'^scheduler/', include(ORGANISATION_SCHEDULER)),
    url(r'^$',
        view=OrganisationDetailView.as_view(),
        name='organisation_detail')
]
ORGANISATIONS = [
    url(r'^(?P<pk>\d+)/', include(ORGANISATION_URL)),
    url(r'^user-access/(?P<pk>\d+)',
        view=UserOrganisationDetail.as_view(),
        name='organisation-user-access'),
    url(r'',
        view=OrganisationListView.as_view(),
        name='organisation_list'),
]
USER_INVITATION_WITH_UUID = [
    url(r'invitation',
        UserOrganisationInvitationPage.as_view(),
        name='user-organisation-invitation-page'),
    url(r'accept',
        UserOrganisationInvitationAccept.as_view(),
        name='user-organisation-invitation-accept'),
    url(r'reject',
        UserOrganisationInvitationReject.as_view(),
        name='user-organisation-invitation-reject'),
    url(r'login',
        UserOrganisationInvitationLogin.as_view(),
        name='user-organisation-invitation-login'),
    url(r'signup',
        UserOrganisationInvitationSignup.as_view(),
        name='user-organisation-invitation-signup'),

]
USER_INVITATION = [
    url(r'^(?P<uuid>[0-9a-f-]+)/', include(USER_INVITATION_WITH_UUID)),
    url(r'^(?P<pk>\d+)',
        UserOrganisationInvitationDetail.as_view(),
        name='user-organisation-invitation-detail'),
]

USER_URL = [
    url(r'^settings', UserSettingsView.as_view(), name='user-settings'),
    url(r'^(?P<username>.+)', UserDetailView.as_view(), name='user-detail'),
]

urlpatterns = [
    url(r'^$', include('civitas.urls')),
    url(r'^$', HomeView.as_view(), name='home'),
    url(r'^community-map', MapView.as_view(), name='map'),
    url(r'^invitation/', include(USER_INVITATION)),
    url(r'^organisation/', include(ORGANISATIONS)),
    url(
        r'^sign-up/subscription',
        SignUpSubscriptionView.as_view(),
        name='signup-subscription'
    ),
    url(r'^sign-up', SignUpView.as_view(), name='signup'),
    url(r'^user/', include(USER_URL)),
]
