__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '27/08/21'

from django.contrib.auth import get_user_model
from django.contrib.auth.decorators import login_required
from django.http import HttpResponseRedirect, HttpResponseForbidden
from django.shortcuts import get_object_or_404, reverse
from helpdesk.models import Ticket
from amlit_helpdesk.models.feature_ticket import FeatureTicket
from amlit.models.organisation import Organisation

User = get_user_model()


@login_required
def delete_ticket(request, ticket_id):
    ticket = get_object_or_404(Ticket, id=ticket_id)
    if request.method == 'DELETE':
        can_delete_ticket = None
        try:
            organisation = Organisation.objects.get(community_code=ticket.featureticket.community_code)
            can_delete_ticket = organisation.has_permission().delete_ticket(request.user)
        except (FeatureTicket.DoesNotExist, Organisation.DoesNotExist):
            pass
        if can_delete_ticket:
            ticket.delete()
            return HttpResponseRedirect(reverse('helpdesk:list'))
        else:
            return HttpResponseForbidden()
