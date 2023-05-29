__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '31/08/21'

from django import forms

from amlit_helpdesk.forms.widget.recurring_type import RecurringTypeInput
from amlit_helpdesk.models.scheduler import SchedulerTemplate
from civitas.models.feature.identifier import FeatureTypeCombination


class SchedulerTemplateForm(forms.ModelForm):
    feature_type_combination = forms.ChoiceField(
        choices=(),
        required=True
    )

    class Meta:
        model = SchedulerTemplate
        widgets = {
            'recurring_type': RecurringTypeInput(True)
        }
        exclude = ()

    def __init__(self, *args, **kwargs):
        super(SchedulerTemplateForm, self).__init__(*args, **kwargs)
        self.fields['feature_type_combination'].choices = (
            (
                type.id, type.__str__()
            ) for type in FeatureTypeCombination.objects.all()
        )
