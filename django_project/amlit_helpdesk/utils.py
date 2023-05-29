__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '27/08/21'

from django.contrib.auth import get_user_model
from amlit_helpdesk.models.feature_ticket import FeatureTicket
from amlit.models.organisation import Organisation

User = get_user_model()


def can_delete_follow_up(ticket, followup, user) -> bool:
    """
    Return if the follow up can be deleted by user
    """
    if followup.ticket != ticket:
        return False
    can_delete_ticket = None
    try:
        organisation = Organisation.objects.get(community_code=ticket.featureticket.community_code)
        can_delete_ticket = organisation.has_permission().delete_ticket(user)
    except (FeatureTicket.DoesNotExist, Organisation.DoesNotExist):
        pass
    return can_delete_ticket or followup.user == user
