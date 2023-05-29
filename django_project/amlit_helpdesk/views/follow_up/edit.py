__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '25/11/21'

from django.contrib.auth import get_user_model
from django.contrib.auth.decorators import login_required
from django.http import HttpResponseRedirect, HttpResponseForbidden
from django.shortcuts import get_object_or_404, reverse
from helpdesk.models import Ticket, FollowUp
from helpdesk.lib import process_attachments
from amlit_helpdesk.models.feature_ticket import FeatureTicket
from amlit.models.organisation import Organisation

User = get_user_model()


@login_required
def followup_edit(request, ticket_id, followup_id):
    """Edit followup options with an ability to change the ticket."""

    ticket = get_object_or_404(Ticket, id=ticket_id)
    followup = get_object_or_404(FollowUp, id=followup_id)
    if request.method == 'POST':
        can_delete_ticket = None
        try:
            organisation = Organisation.objects.get(community_code=ticket.featureticket.community_code)
            can_delete_ticket = organisation.has_permission().delete_ticket(request.user)
        except (FeatureTicket.DoesNotExist, Organisation.DoesNotExist):
            pass
        if (can_delete_ticket or followup.user == request.user) and followup.title != 'Ticket Opened':
            if request.method == 'POST':
                try:
                    followup.comment = request.POST['comment']
                    followup.save()
                except KeyError:
                    pass

                if request.FILES:
                    process_attachments(followup, request.FILES.getlist('attachment'))
            return HttpResponseRedirect(reverse('helpdesk:view', args=[ticket.id]))
        else:
            return HttpResponseForbidden()
