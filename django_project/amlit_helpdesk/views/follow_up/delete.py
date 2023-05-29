__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '27/08/21'

from django.contrib.auth import get_user_model
from django.contrib.auth.decorators import login_required
from django.http import HttpResponseRedirect, HttpResponseForbidden
from django.shortcuts import get_object_or_404, reverse
from helpdesk.models import Ticket, FollowUp
from amlit_helpdesk.utils import can_delete_follow_up

User = get_user_model()


@login_required
def followup_delete(request, ticket_id, followup_id):
    if request.method == 'DELETE':
        ticket = get_object_or_404(Ticket, id=ticket_id)
        followup = get_object_or_404(FollowUp, id=followup_id)
        if can_delete_follow_up(ticket, followup, request.user) and followup.title != 'Ticket Opened':
            followup.delete()
            return HttpResponseRedirect(reverse('helpdesk:view', args=[ticket.id]))
        else:
            return HttpResponseForbidden()
