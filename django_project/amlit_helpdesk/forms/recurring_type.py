__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '31/08/21'

from django import forms
from helpdesk.models import Ticket
from amlit.models.preferences import SitePreferences
from amlit_helpdesk.models.recurring_ticket import RecurringTicket
from amlit_helpdesk.forms.widget.recurring_type import RecurringTypeInput


class RecurringTicketForm(forms.ModelForm):
    class Meta:
        model = RecurringTicket
        widgets = {
            'recurring_type': RecurringTypeInput()
        }
        exclude = ()

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        pref = SitePreferences.preferences()
        self.fields['original_ticket'].queryset = Ticket.objects.filter(
            queue__in=pref.recurred_queues_ids
        )
