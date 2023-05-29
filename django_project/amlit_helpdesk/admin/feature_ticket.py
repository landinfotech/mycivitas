__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '05/03/21'

from django.contrib import admin
from django.shortcuts import reverse
from django.utils.html import mark_safe
from amlit_helpdesk.models.feature_ticket import FeatureTicket


def assign_community_code_to_ticket(modeladmin, request, queryset):
    for ticket in queryset:
        ticket.assign_community_code()


class FeatureTicketAdmin(admin.ModelAdmin):
    list_display = ('features', 'community_code', 'assigned_to', 'due_date', 'ticket_url', 'recurring_type', 'next_date')
    readonly_fields = ('recurring_type', 'next_date')
    actions = (assign_community_code_to_ticket,)

    def assigned_to(self, object: FeatureTicket):
        return object.ticket.assigned_to

    def due_date(self, object: FeatureTicket):
        return object.ticket.due_date

    def ticket_url(self, object: FeatureTicket):
        return mark_safe(f'<a href="{reverse("helpdesk:view", args=[object.ticket.pk])}">ticket</a>')


admin.site.register(FeatureTicket, FeatureTicketAdmin)
