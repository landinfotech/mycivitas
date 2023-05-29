from django.contrib.auth import get_user_model
from helpdesk.models import Ticket
from amlit.models.organisation import Organisation

User = get_user_model()


def amlit_assign_to_list(ticket: Ticket):
    """ Return assign to list for the ticket """
    try:
        return User.objects.filter(
            id__in=Organisation.objects.get(
                community_code=ticket.featureticket.community_code).userorganisation_set.values_list(
                'user', flat=True
            )
        )
    except Organisation.DoesNotExist:
        return User.objects.none()


Ticket.get_assign_to_list = amlit_assign_to_list
