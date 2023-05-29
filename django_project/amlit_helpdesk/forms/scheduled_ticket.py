__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '27/08/21'

from django import forms
from django.utils.translation import ugettext_lazy as _

from amlit_helpdesk.forms.recurring_type import RecurringTypeInput
from civitas.models.feature.identifier import FeatureTypeCombination

DEFAULT_PRIORITY = 3


class ScheduledTicketForm(forms.Form):
    feature_type_combination = forms.ChoiceField(
        choices=(),
        required=True,
        label=_('Asset Type')
    )
    title = forms.CharField(
        max_length=100,
        required=True,
        widget=forms.TextInput(attrs={'class': 'form-control'}),
        label=_('Activity Summary'),
    )
    description = forms.CharField(
        widget=forms.Textarea(attrs={'class': 'form-control'}),
        label=_('Activity Description'),
        required=True,
        help_text=_(
            'Please be as descriptive as possible and include all details'),
    )
    recurring_type = forms.CharField(
        widget=RecurringTypeInput(
            is_scheduler=True,
            attrs={'class': 'form-control'}
        ),
        label=_('Recurring ticket by'),
        required=True,
        help_text=_(
            'A new ticket with the same details as '
            'this one will be created on each recurrence.'),
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
        super(ScheduledTicketForm, self).__init__(*args, **kwargs)
        self.fields['feature_type_combination'].choices = (
            (
                type.id, type.__str__()
            ) for type in FeatureTypeCombination.objects.all()
        )
        if assigned_to_choices:
            self.fields['assigned_to'].choices = [('', '--------')] + [
                (u.id, u.get_username()) for u in assigned_to_choices
            ]
