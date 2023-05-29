import json

from django.conf import settings
from django.contrib.auth.mixins import LoginRequiredMixin
from django.core.exceptions import PermissionDenied
from django.forms.models import model_to_dict
from django.http import JsonResponse
from django.shortcuts import reverse, get_object_or_404
from django.views.generic import DetailView, ListView

from amlit.forms.organisation import (
    UserOrganisationForm,
    UserOrganisationInvitationForm
)
from amlit.models.organisation import Organisation
from amlit_helpdesk.forms.scheduled_ticket import ScheduledTicketForm


class OrganisationListView(LoginRequiredMixin, ListView):
    """ Showing list of organisation of an user
    """
    template_name = 'pages/organisations/list.html'
    model = Organisation

    def get_queryset(self):
        return Organisation.by_user.all_role(self.request.user)


class OrganisationDetailView(LoginRequiredMixin, DetailView):
    """ Showing Organisation detail
    """
    model = Organisation
    template_name = 'pages/organisations/detail.html'

    def get_success_url(self):
        return reverse('organisation_list')

    def get_context_data(self, **kwargs):
        context = super(OrganisationDetailView, self).get_context_data(
            **kwargs)
        users = {
            'form': UserOrganisationForm(),
            'data': [],
            'pendings': []
        }
        for user_org in self.object.userorganisation_set.filter(
                user=self.object.owner):
            users['data'].append(
                UserOrganisationForm(
                    initial=model_to_dict(user_org),
                    instance=user_org)
            )
        for user_org in self.object.userorganisation_set.exclude(
                user=self.object.owner).order_by('user__email'):
            users['data'].append(
                UserOrganisationForm(
                    initial=model_to_dict(user_org),
                    instance=user_org)
            )
        for user_org in self.object.userorganisationinvitation_set.all().order_by(
                'email'):
            users['pendings'].append(
                UserOrganisationInvitationForm(
                    initial=model_to_dict(user_org),
                    instance=user_org)
            )
        context['users'] = users
        context['users_count'] = len(users['data'])
        
        context['scheduled_form'] = ScheduledTicketForm(
            assigned_to_choices=self.object.operators)
        return context


class SubscriptionView(LoginRequiredMixin, DetailView):
    """ Subscription view for an organisation
    """
    template_name = "pages/organisations/subscription.html"
    model = Organisation

    def get_context_data(self, **kwargs):
        context = super(SubscriptionView, self).get_context_data(**kwargs)
        if not self.object.is_owner(self.request.user):
            raise PermissionDenied('You do not have permission.')

        context['url_submit'] = reverse(
            'organisation_subscription', args=[self.object.pk]
        )
        return context

    def post(self, request, *args, **kwargs):
        organisation = self.get_object()
        data = json.loads(request.body)
        try:
            organisation.subscribe(request.user, data)
            return JsonResponse({'Result': 'OK'})

        except Exception as e:
            return JsonResponse({'error': (e.args[0])}, status=403)


class SubscriptionChangeView(LoginRequiredMixin, DetailView):
    """ Subscription change view for an organisation
    """
    template_name = "pages/organisations/subscription-change.html"
    model = Organisation

    def get_context_data(self, **kwargs):
        context = super(SubscriptionChangeView, self).get_context_data(
            **kwargs)
        if not self.object.is_owner(self.request.user):
            raise PermissionDenied('You do not have permission.')

        return context

    def post(self, request, *args, **kwargs):
        organisation = self.get_object()
        data = json.loads(request.body)
        plan = get_object_or_404(Plan, id=data.get('plan_id', 0))
        organisation.change_plan(plan)
        return JsonResponse({'Result': 'OK'})


class SubscriptionCompleteView(LoginRequiredMixin, DetailView):
    """ Page when subscription is completed
    """
    template_name = "pages/organisations/complete.html"
    model = Organisation


class SignupCompleteView(LoginRequiredMixin, DetailView):
    """ Page when signup is completed
    """
    template_name = "registration/complete.html"
    model = Organisation
