__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '27/08/21'

from django import forms
from django.utils.translation import ugettext_lazy as _
from helpdesk.forms import TicketForm, CUSTOMFIELD_DATE_FORMAT, CUSTOMFIELD_DATETIME_FORMAT
from helpdesk.models import Ticket
from amlit_helpdesk.forms.recurring_type import RecurringTypeInput
from amlit_helpdesk.forms.widget.expected_time import ExpectedTimeInput

DEFAULT_PRIORITY = 3


class AmlitTicketForm(TicketForm):
    title = forms.CharField(
        max_length=100,
        required=True,
        widget=forms.TextInput(attrs={'class': 'form-control'}),
        label=_('Summary of issue or task'),
    )

    body = forms.CharField(
        widget=forms.Textarea(attrs={'class': 'form-control'}),
        label=_('Description of issue or task'),
        required=True,
        help_text=_('Please be as descriptive as possible and include all details'),
    )
    queue = forms.ChoiceField(
        widget=forms.Select(attrs={'class': 'form-control'}),
        label=_('Type'),
        required=True,
        choices=()
    )
    priority = forms.ChoiceField(
        widget=forms.Select(attrs={'class': 'form-control'}),
        choices=Ticket.PRIORITY_CHOICES,
        required=True,
        initial=DEFAULT_PRIORITY,
        label=_('Priority'),
        help_text=f"Please select a priority. If unsure, leave it as '{Ticket.PRIORITY_CHOICES[DEFAULT_PRIORITY - 1][1]}'.",
    )
    start_date = forms.DateTimeField(
        widget=forms.TextInput(attrs={'class': 'form-control', 'autocomplete': 'off'}),
        required=True,
        input_formats=[CUSTOMFIELD_DATE_FORMAT, CUSTOMFIELD_DATETIME_FORMAT, '%d/%m/%Y', '%m/%d/%Y', "%d.%m.%Y"],
        label=_('Start on'),
    )
    expected_time = forms.CharField(
        widget=ExpectedTimeInput(attrs={'class': 'form-control'}),
        required=False,
        label=_('Expected time to complete task'),
    )
    recurring_type = forms.CharField(
        required=False,
        widget=RecurringTypeInput(attrs={'class': 'form-control'}),
        label=_('Recurring ticket by'),
        help_text=_(
            'A new ticket with the same details as this one will be created on each recurrence.'),
    )
    attachment = forms.FileField(
        widget=forms.FileInput(attrs={'class': 'form-control-file'}),
        required=False,
        label=_('Attach File'),
        help_text=_('You can attach a file such as a document or photo to this ticket.'),
    )
    assigned_to = forms.ChoiceField(
        widget=(
            forms.Select(attrs={'class': 'form-control'})
        ),
        required=False,
        label=_('Assign to')
    )

    def __init__(self, *args, **kwargs):
        assigned_to_choices = None
        try:
            assigned_to_choices = kwargs.pop("assigned_to_choices")
        except KeyError:
            pass
        super(AmlitTicketForm, self).__init__(*args, **kwargs)
        self.fields['submitter_email'].widget = forms.HiddenInput()
        if assigned_to_choices:
            self.fields['assigned_to'].choices = [(0, '--------')] + [(u.id, u.get_username()) for u in assigned_to_choices]

        try:
            self.fields['queue'].initial = self.initial['queue']
        except KeyError:
            pass