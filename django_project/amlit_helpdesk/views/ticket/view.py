__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '27/08/21'

from django.contrib.auth import get_user_model
from django.contrib.auth.decorators import login_required
from django.contrib.contenttypes.models import ContentType
from django.db.models import Q
from django.http import HttpResponseRedirect
from django.shortcuts import render, get_object_or_404
from django.urls import reverse
from django.utils.translation import ugettext_lazy as _
from helpdesk import settings as helpdesk_settings
from helpdesk.models import Ticket, PreSetReply
from helpdesk.user import HelpdeskUser
from helpdesk.views.staff import (
    update_ticket, return_ticketccstring_and_show_subscribe,
    subscribe_staff_member_to_ticket, _get_queue_choices
)
from amlit.models.organisation import Organisation
from amlit_helpdesk.models.feature_ticket import FeatureTicket
from amlit_helpdesk.models.recurring_ticket import RecurringTicket
from amlit_helpdesk.forms.ticket import AmlitTicketForm

User = get_user_model()


@login_required
def view_ticket(request, ticket_id):
    ticket = get_object_or_404(Ticket, id=ticket_id)

    if 'take' in request.GET:
        # Allow the user to assign the ticket to themselves whilst viewing it.

        # Trick the update_ticket() view into thinking it's being called with
        # a valid POST.
        request.POST = {
            'owner': request.user.id,
            'public': 1,
            'title': ticket.title,
            'comment': ''
        }
        return update_ticket(request, ticket_id)

    if 'subscribe' in request.GET:
        # Allow the user to subscribe him/herself to the ticket whilst viewing it.
        ticket_cc, show_subscribe = \
            return_ticketccstring_and_show_subscribe(request.user, ticket)
        if show_subscribe:
            subscribe_staff_member_to_ticket(ticket, request.user)
            return HttpResponseRedirect(reverse('helpdesk:view', args=[ticket.id]))

    if 'close' in request.GET and ticket.status == Ticket.RESOLVED_STATUS:
        if not ticket.assigned_to:
            owner = 0
        else:
            owner = ticket.assigned_to.id

        # Trick the update_ticket() view into thinking it's being called with
        # a valid POST.
        request.POST = {
            'new_status': Ticket.CLOSED_STATUS,
            'public': 1,
            'owner': owner,
            'title': ticket.title,
            'comment': _('Accepted resolution and closed ticket'),
        }

        return update_ticket(request, ticket_id)

    if helpdesk_settings.HELPDESK_STAFF_ONLY_TICKET_OWNERS:
        users = User.objects.filter(is_active=True, is_staff=True).order_by(User.USERNAME_FIELD)
    else:
        users = User.objects.filter(is_active=True).order_by(User.USERNAME_FIELD)

    queues = HelpdeskUser(request.user).get_queues()
    queue_choices = _get_queue_choices(queues)

    form = None
    can_comment = None
    can_edit_ticket = False
    can_delete_ticket = False
    try:
        organisation = Organisation.objects.get(community_code=ticket.featureticket.community_code)
        can_comment = organisation.has_permission().comment_ticket(request.user)
        can_edit_ticket = organisation.has_permission().edit_ticket(request.user)
        if organisation.has_permission().edit_ticket(request.user):
            recurring = RecurringTicket.get_recurring(ticket)
            form = AmlitTicketForm(
                initial={
                    'title': ticket.title,
                    'queue': ticket.queue.id,
                    'due_date': ticket.due_date,
                    'start_date': ticket.start_date,
                    'expected_time': ticket.expected_time,
                    'priority': ticket.priority,
                    'assigned_to': ticket.assigned_to,
                    'recurring_type': recurring.recurring_type if recurring and recurring.active else None
                },
                queue_choices=queue_choices,
                assigned_to_choices=organisation.operators
            )
        can_delete_ticket = organisation.has_permission().delete_ticket(request.user)
    except (FeatureTicket.DoesNotExist, Organisation.DoesNotExist):
        pass

    ticketcc_string, show_subscribe = \
        return_ticketccstring_and_show_subscribe(request.user, ticket)

    submitter_userprofile = ticket.get_submitter_userprofile()
    if submitter_userprofile is not None:
        content_type = ContentType.objects.get_for_model(submitter_userprofile)
        submitter_userprofile_url = reverse(
            'admin:{app}_{model}_change'.format(app=content_type.app_label, model=content_type.model),
            kwargs={'object_id': submitter_userprofile.id}
        )
    else:
        submitter_userprofile_url = None
    return render(request, 'helpdesk/ticket.html', {
        'ticket': ticket,
        'submitter_userprofile_url': submitter_userprofile_url,
        'form': form,
        'active_users': users,
        'priorities': Ticket.PRIORITY_CHOICES,
        'preset_replies': PreSetReply.objects.filter(
            Q(queues=ticket.queue) | Q(queues__isnull=True)),
        'ticketcc_string': ticketcc_string,
        'SHOW_SUBSCRIBE': show_subscribe,
        'can_comment': can_comment,
        'can_recurring': RecurringTicket.can_recurring(ticket),
        'can_edit_ticket': can_edit_ticket,
        'can_delete_ticket': can_delete_ticket
    })
