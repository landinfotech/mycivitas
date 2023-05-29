from django import template
from helpdesk.models import Ticket
from amlit.models.organisation import Organisation

register = template.Library()


@register.simple_tag(name='has_edit_ticket_perm')
def has_edit_ticket_perm(ticket: Ticket, user):
    """ is user has ticket editing permissions """
    try:
        return Organisation.objects.get(
            community_code=ticket.featureticket.community_code).has_permission().edit_ticket(user)
    except Organisation.DoesNotExist:
        return False
