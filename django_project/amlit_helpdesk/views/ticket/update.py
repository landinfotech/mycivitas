__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '27/08/21'

import re
from datetime import date, timedelta, datetime
from django.contrib.auth import get_user_model
from django.contrib.auth.decorators import login_required
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.translation import ugettext_lazy as _
from helpdesk import settings as helpdesk_settings
from helpdesk.decorators import is_helpdesk_staff
from helpdesk.lib import (
    safe_template_context,
    process_attachments
)
from helpdesk.models import FollowUp, Ticket, TicketChange, format_time_spent
from helpdesk.views.staff import (
    return_to_ticket, return_ticketccstring_and_show_subscribe,
    subscribe_staff_member_to_ticket
)
from amlit_helpdesk.models.recurring_ticket import RecurringTicket

User = get_user_model()


def update_ticket_data(ticket, the_user, data, FILES=None):
    date_re = re.compile(
        r'(?P<year>\d{4})-(?P<month>\d{1,2})-(?P<day>\d{1,2})$'
    )

    comment = data.get('comment', '')
    new_status = int(data.get('new_status', ticket.status))
    title = data.get('title', ticket.title)
    public = data.get('public', False)
    owner = int(data.get('owner', -1))
    if owner == -1:
        assign_to = data.get('assigned_to', -1)
        if assign_to:
            owner = int(assign_to)
    priority = int(data.get('priority', ticket.priority))
    due_date_year = int(data.get('due_date_year', 0))
    due_date_month = int(data.get('due_date_month', 0))
    due_date_day = int(data.get('due_date_day', 0))

    if data.get("time_spent"):
        (hours, minutes) = [int(f) for f in data.get("time_spent").split(":")]
        time_spent = timedelta(hours=hours, minutes=minutes)
    else:
        time_spent = None

    if data.get("expected_time"):
        (hours, minutes) = [int(f) for f in data.get("expected_time").split(":")]
        expected_time = timedelta(hours=hours, minutes=minutes)
    else:
        expected_time = None
    # NOTE: jQuery's default for dates is mm/dd/yy
    # very US-centric but for now that's the only format supported
    # until we clean up code to internationalize a little more
    due_date = data.get('due_date', None) or None
    start_date = data.get('start_date', None) or None

    if due_date is not None:
        # based on Django code to parse dates:
        # https://docs.djangoproject.com/en/2.0/_modules/django/utils/dateparse/
        match = date_re.match(due_date)
        if match:
            kw = {k: int(v) for k, v in match.groupdict().items()}
            due_date = timezone.make_aware(datetime(**kw))
    else:
        # old way, probably deprecated?
        if not (due_date_year and due_date_month and due_date_day):
            due_date = ticket.due_date
        else:
            # NOTE: must be an easier way to create a new date than doing it this way?
            if ticket.due_date:
                due_date = ticket.due_date
            else:
                due_date = timezone.now()
            due_date = due_date.replace(due_date_year, due_date_month, due_date_day)

    if start_date is not None:
        # based on Django code to parse dates:
        # https://docs.djangoproject.com/en/2.0/_modules/django/utils/dateparse/
        match = date_re.match(start_date)
        if match:
            kw = {k: int(v) for k, v in match.groupdict().items()}
            start_date = timezone.make_aware(datetime(**kw))

    old_recurring_type = None
    try:
        old_recurring_type = ticket.last_ticket.recurring_type
    except RecurringTicket.DoesNotExist:
        pass
    recurring_type = data.get('recurring_type', None)
    if recurring_type is None:
        recurring_type = old_recurring_type

    recurring_ticket = RecurringTicket.get_recurring(ticket)
    recurring_active = recurring_ticket.active if recurring_ticket else False
    recurring_changed = (
            (recurring_type and not recurring_active) or
            (not recurring_type and recurring_active) or
            (recurring_type and recurring_type != old_recurring_type)
    )
    no_changes = all([
        not FILES,
        not comment,
        new_status == ticket.status,
        title == ticket.title,
        priority == int(ticket.priority),
        due_date == ticket.due_date,
        (start_date and start_date == ticket.start_date),
        expected_time == ticket.expected_time,
        (owner == -1) or (not owner and not ticket.assigned_to) or
        (owner and User.objects.get(id=owner) == ticket.assigned_to),
        not recurring_changed
    ])
    if no_changes:
        return False

    # We need to allow the 'ticket' and 'queue' contexts to be applied to the
    # comment.
    context = safe_template_context(ticket)

    from django.template import engines
    template_func = engines['django'].from_string
    # this prevents system from trying to render any template tags
    # broken into two stages to prevent changes from first replace being themselves
    # changed by the second replace due to conflicting syntax
    comment = comment.replace('{%', 'X-HELPDESK-COMMENT-VERBATIM').replace('%}', 'X-HELPDESK-COMMENT-ENDVERBATIM')
    comment = comment.replace(
        'X-HELPDESK-COMMENT-VERBATIM', '{% verbatim %}{%'
    ).replace(
        'X-HELPDESK-COMMENT-ENDVERBATIM', '%}{% endverbatim %}'
    )
    # render the neutralized template
    comment = template_func(comment).render(context)

    if owner == -1 and ticket.assigned_to:
        owner = ticket.assigned_to.id

    f = FollowUp(ticket=ticket, date=timezone.now(), comment=comment,
                 time_spent=time_spent)

    if is_helpdesk_staff(the_user):
        f.user = the_user

    f.public = public

    reassigned = False

    old_owner = ticket.assigned_to
    if owner != -1:
        if owner != 0 and ((ticket.assigned_to and owner != ticket.assigned_to.id) or not ticket.assigned_to):
            new_user = User.objects.get(id=owner)
            f.title = _('Assigned to %(username)s') % {
                'username': new_user.get_username(),
            }
            ticket.assigned_to = new_user
            reassigned = True
        # user changed owner to 'unassign'
        elif owner == 0 and ticket.assigned_to is not None:
            f.title = _('Unassigned')
            ticket.assigned_to = None

    old_status_str = ticket.get_status_display()
    old_status = ticket.status
    if new_status != ticket.status:
        ticket.status = new_status
        ticket.save()
        f.new_status = new_status
        if f.title:
            f.title += ' and %s' % ticket.get_status_display()
        else:
            f.title = '%s' % ticket.get_status_display()

    if not f.title:
        if f.comment:
            f.title = _('Comment')
        else:
            f.title = _('Updated')

    f.save()

    files = []
    if FILES:
        files = process_attachments(f, FILES.getlist('attachment'))

    if title and title != ticket.title:
        c = TicketChange(
            followup=f,
            field=_('Title'),
            old_value=ticket.title,
            new_value=title,
        )
        c.save()
        ticket.title = title

    if new_status != old_status:
        c = TicketChange(
            followup=f,
            field=_('Status'),
            old_value=old_status_str,
            new_value=ticket.get_status_display(),
        )
        c.save()

    if ticket.assigned_to != old_owner:
        c = TicketChange(
            followup=f,
            field=_('Operator'),
            old_value=old_owner,
            new_value=ticket.assigned_to,
        )
        c.save()

    if priority != ticket.priority:
        old_priority = ticket.priority
        try:
            old_priority = Ticket.PRIORITY_CHOICES[ticket.priority - 1][1]
        except IndexError:
            pass
        new_priority = priority
        try:
            new_priority = Ticket.PRIORITY_CHOICES[priority - 1][1]
        except IndexError:
            pass
        c = TicketChange(
            followup=f,
            field=_('Priority'),
            old_value=old_priority,
            new_value=new_priority,
        )
        c.save()
        ticket.priority = priority

    if due_date != ticket.due_date:
        c = TicketChange(
            followup=f,
            field=_('Due date'),
            old_value=ticket.due_date,
            new_value=due_date,
        )
        c.save()
        ticket.due_date = due_date

    if start_date and start_date != ticket.start_date:
        c = TicketChange(
            followup=f,
            field=_('Start date'),
            old_value=ticket.start_date,
            new_value=start_date,
        )
        c.save()
        ticket.start_date = start_date
        recurring_ticket = RecurringTicket.get_recurring(ticket)
        if recurring_ticket:
            recurring_ticket.save()

    if expected_time != ticket.expected_time:
        c = TicketChange(
            followup=f,
            field=_('Expected time'),
            old_value=format_time_spent(ticket.expected_time),
            new_value=format_time_spent(expected_time),
        )
        c.save()
        ticket.expected_time = expected_time

    if recurring_changed:
        recurring_ticket = RecurringTicket.get_recurring(ticket)
        if not recurring_ticket:
            recurring_ticket = RecurringTicket(
                original_ticket=ticket,
                recurring_type=recurring_type if recurring_type else RecurringTicket.WEEKLY_FROM_START_DATE,
                active=True
            )

        if recurring_type == '':
            recurring_ticket.active = False
            recurring_ticket.save()

            c = TicketChange(
                followup=f,
                field=_('Recurring'),
                old_value=old_recurring_type,
                new_value='not active',
            )
            c.save()
        else:
            # create ticket change log
            c = TicketChange(
                followup=f,
                field=_('Recurring'),
                old_value=old_recurring_type if recurring_ticket.active else 'not active',
                new_value=recurring_type,
            )
            c.save()

            recurring_ticket.active = True
            recurring_ticket.recurring_type = recurring_type
            recurring_ticket.save()

    if new_status in (Ticket.RESOLVED_STATUS, Ticket.CLOSED_STATUS):
        if new_status == Ticket.RESOLVED_STATUS or ticket.resolution is None:
            ticket.resolution = comment

    # ticket might have changed above, so we re-instantiate context with the
    # (possibly) updated ticket.
    context = safe_template_context(ticket)
    context.update(
        resolution=ticket.resolution,
        comment=f.comment,
    )

    messages_sent_to = set()
    try:
        messages_sent_to.add(the_user.email)
    except AttributeError:
        pass
    if public and (f.comment or (
            f.new_status in (Ticket.RESOLVED_STATUS,
                             Ticket.CLOSED_STATUS))):
        if f.new_status == Ticket.RESOLVED_STATUS:
            template = 'resolved_'
        elif f.new_status == Ticket.CLOSED_STATUS:
            template = 'closed_'
        else:
            template = 'updated_'

        roles = {
            'submitter': (template + 'submitter', context),
            'ticket_cc': (template + 'cc', context),
        }
        if ticket.assigned_to and ticket.assigned_to.usersettings_helpdesk.email_on_ticket_change:
            roles['assigned_to'] = (template + 'cc', context)
        messages_sent_to.update(ticket.send(roles, dont_send_to=messages_sent_to, fail_silently=True, files=files, ))

    if reassigned:
        template_staff = 'assigned_owner'
    elif f.new_status == Ticket.RESOLVED_STATUS:
        template_staff = 'resolved_owner'
    elif f.new_status == Ticket.CLOSED_STATUS:
        template_staff = 'closed_owner'
    else:
        template_staff = 'updated_owner'

    if ticket.assigned_to and (
            ticket.assigned_to.usersettings_helpdesk.email_on_ticket_change
            or (reassigned and ticket.assigned_to.usersettings_helpdesk.email_on_ticket_assigned)
    ):
        messages_sent_to.update(ticket.send(
            {'assigned_to': (template_staff, context)},
            dont_send_to=messages_sent_to,
            fail_silently=True,
            files=files,
        ))

    if reassigned:
        template_cc = 'assigned_cc'
    elif f.new_status == Ticket.RESOLVED_STATUS:
        template_cc = 'resolved_cc'
    elif f.new_status == Ticket.CLOSED_STATUS:
        template_cc = 'closed_cc'
    else:
        template_cc = 'updated_cc'

    messages_sent_to.update(ticket.send(
        {'ticket_cc': (template_cc, context)},
        dont_send_to=messages_sent_to,
        fail_silently=True,
        files=files,
    ))

    ticket.save()

    # auto subscribe user if enabled
    if helpdesk_settings.HELPDESK_AUTO_SUBSCRIBE_ON_TICKET_RESPONSE and the_user.is_authenticated:
        ticketcc_string, SHOW_SUBSCRIBE = return_ticketccstring_and_show_subscribe(the_user, ticket)
        if SHOW_SUBSCRIBE:
            subscribe_staff_member_to_ticket(ticket, the_user)

    return True


@login_required
def update_ticket(request, ticket_id):
    ticket = get_object_or_404(Ticket, id=ticket_id)
    update_ticket_data(ticket, request.user, request.POST, request.FILES)
    return return_to_ticket(request.user, helpdesk_settings, ticket)
