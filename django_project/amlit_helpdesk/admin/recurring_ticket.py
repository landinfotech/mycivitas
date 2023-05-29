__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '05/03/21'

from django.contrib import admin
from django.shortcuts import reverse
from django.utils.html import mark_safe
from amlit_helpdesk.models.feature_ticket import FeatureTicket
from amlit_helpdesk.models.recurring_ticket import RecurringTicket
from amlit_helpdesk.tasks import recurring_tickets_check
from amlit_helpdesk.forms.recurring_type import RecurringTicketForm


def check_all_recurring_event(modeladmin, request, queryset):
    recurring_tickets_check()


class RecurringTicketAdmin(admin.ModelAdmin):
    list_display = ('id', 'active', 'recurring_type', 'next_date', 'assigned_to', 'due_date', 'ticket_url', 'feature_ticket_url')
    readonly_fields = ('next_date', 'last_ticket', 'tickets')
    list_editable = ('active',)
    form = RecurringTicketForm
    actions = (check_all_recurring_event,)

    def feature_ticket_url(self, object: RecurringTicket):
        try:
            url = reverse("admin:amlit_helpdesk_featureticket_change", args=(object.last_ticket.featureticket.pk,))
            return mark_safe(f'<a href="{url}">{object.last_ticket.featureticket.__str__()}</a>')
        except FeatureTicket.DoesNotExist:
            return '-'

    def assigned_to(self, object: RecurringTicket):
        return object.last_ticket.assigned_to

    def due_date(self, object: RecurringTicket):
        return object.last_ticket.due_date

    def ticket_url(self, object: RecurringTicket):
        return mark_safe(f'<a href="{reverse("helpdesk:view", args=[object.last_ticket.pk])}">Ticket</a>')

    # regular stuff
    class Media:
        js = (
            'libs/jquery.js/3.4.1/jquery.min.js',
            'libs/jquery-ui/1.12.1/jquery-ui.js',
            'js/forms/widget/recurring_type.js',
        )


admin.site.register(RecurringTicket, RecurringTicketAdmin)
