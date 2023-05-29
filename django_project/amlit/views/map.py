__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '13/09/19'

from django.contrib.auth.mixins import LoginRequiredMixin
from django.db import ProgrammingError
from django.shortcuts import render
from django.views.generic import View

from amlit_helpdesk.views.form_view import create_ticket
from civitas.models.community import Community


class MapView(LoginRequiredMixin, View):
    template_name = 'map/map.html'

    def get_context_data(self, **kwargs):
        context = {}
        count = Community.objects.count()
        view = create_ticket(self.request, self.args, **kwargs)
        context['create_ticket_form'] = view.context_data['form']
        return context

    def get(self, request, *args, **kwargs):
        try:
            return render(
                request, self.template_name,
                self.get_context_data(**kwargs)
            )
        except ProgrammingError:
            return render(
                request, 'pages/500.html',
                {
                    'error': (
                        'Civitas database schema is empty. '
                        'Please restore it by asking admin for the schema.'
                    )
                }
            )
