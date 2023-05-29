from django import forms
from amlit_helpdesk.models.recurring_ticket import RecurringTicket


class RecurringTypeInput(forms.widgets.Input):
    template_name = 'forms/widgets/recurring_type.html'
    input_type = 'text'
    custom_recurrence = 'Custom recurrence'
    is_scheduler = False

    def __init__(self, is_scheduler=False, attrs=None):
        super().__init__(attrs)
        self.is_scheduler = is_scheduler

    def get_context(self, name, value, attrs):
        context = super(RecurringTypeInput, self).get_context(name, value, attrs)

        if self.is_scheduler:
            default_choices = [self.custom_recurrence]
        else:
            default_choices = RecurringTicket.RECURRING_FROM_START_DATE + [self.custom_recurrence]

        context['value_choice'] = None
        if value and value not in RecurringTicket.RECURRING_FROM_TODAY + RecurringTicket.RECURRING_FROM_START_DATE:
            context['value_choice'] = value
        context['default_choices'] = default_choices
        context['custom'] = self.custom_recurrence
        return context
