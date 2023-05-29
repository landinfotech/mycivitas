from django import forms
from datetime import timedelta
from helpdesk.models import format_time_spent


class ExpectedTimeInput(forms.widgets.Input):
    template_name = 'forms/widgets/expected_time.html'

    def get_context(self, name, value: timedelta, attrs):
        context = super(ExpectedTimeInput, self).get_context(name, value, attrs)
        if value:
            context['value'] = format_time_spent(value).replace('h', '').replace('m', '')
            context['hours'] = context['value'].split(':')[0]
            context['minutes'] = context['value'].split(':')[1]
        return context

    def value_from_datadict(self, data, files, name):
        if data.get('expected_time', None):
            (hours, minutes) = [int(f) for f in data.get('expected_time').split(":")]
            return timedelta(hours=hours, minutes=minutes)
        else:
            return
