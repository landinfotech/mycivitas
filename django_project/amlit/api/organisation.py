import json
from django.db.models import Q
from django.http import HttpResponseBadRequest, HttpResponseForbidden, HttpResponse
from django.shortcuts import get_object_or_404, reverse, redirect
from rest_framework.response import Response
from rest_framework.views import APIView
from amlit.models import (
    User, UserRole, Organisation, UserOrganisation, UserOrganisationInvitation
)
from amlit.forms.organisation import UserOrganisationInvitationForm
from amlit_helpdesk.forms.scheduled_ticket import ScheduledTicketForm
from amlit_helpdesk.models.scheduler import SchedulerOrganisation, SchedulerTemplate
from amlit_helpdesk.serializer.scheduler import (
    SchedulerTemplateSerializer, SchedulerOrganisationSerializer
)


class OrganisationAvailableUserSearch(APIView):
    """ Return user that available for organisation """

    def get(self, request, pk):
        """ Return data of features """
        q = request.GET.get('q', 'none')
        org = get_object_or_404(Organisation, pk=pk)
        return Response(
            [getattr(user, User.USERNAME_FIELD) for user in User.objects.filter(
                Q(first_name__icontains=q) |
                Q(last_name__icontains=q) |
                Q(email__icontains=q)
            ).exclude(
                id__in=list(org.userorganisation_set.values_list('user', flat=True))
            )]
        )


class OrganisationInvitation(APIView):
    """ Create user invitation for an organisation """

    def post(self, request, pk):
        """ Return data of features """
        data = request.data
        org = get_object_or_404(Organisation, pk=pk)
        try:
            if not org.has_permission().assign_user(request.user):
                return HttpResponseForbidden()
            if org.able_to_add_user:
                email = data.get('email', None)
                # create invitation if user has not been invited or already have access
                if not org.userorganisationinvitation_set.filter(
                        email=email
                ).first() and not org.userorganisation_set.filter(
                    **{
                        'user__{}'.format(User.USERNAME_FIELD): email,
                        'organisation': org
                    }
                ).first():
                    form = UserOrganisationInvitationForm(data)
                    if form.is_valid():
                        UserOrganisationInvitation.objects.get_or_create(
                            email=email,
                            organisation=org,
                            role=UserRole.objects.get(id=data.get('role', None))
                        )
                    else:
                        return HttpResponseBadRequest("The data is wrong.")

                return redirect(
                    reverse('organisation_detail', args=[pk]) + '#manage-access'
                )
            else:
                return HttpResponseBadRequest("Can't add new user anymore.")
        except UserRole.DoesNotExist:
            return HttpResponseBadRequest('User role does not exist')


class UserOrganisationDetail(APIView):
    """ API for user organisation/access"""

    def delete(self, request, pk):
        """ Return data of features """
        access = get_object_or_404(UserOrganisation, pk=pk)
        if not access.organisation.has_permission().assign_user(request.user):
            return HttpResponseForbidden()
        access.delete()
        return HttpResponse('OK')

    def put(self, request, pk):
        """ Return data of features """
        access = get_object_or_404(UserOrganisation, pk=pk)
        if not access.organisation.has_permission().assign_user(request.user):
            return HttpResponseForbidden()
        try:
            access.role = UserRole.objects.get(
                id=request.data.get('role', 0))
            access.save()
            return HttpResponse('OK')
        except UserRole.DoesNotExist:
            return HttpResponseBadRequest()


class UserOrganisationInvitationDetail(APIView):
    """ API for invitation """

    def delete(self, request, pk):
        """ Return data of features """
        invitation = get_object_or_404(UserOrganisationInvitation, pk=pk)
        if not invitation.organisation.has_permission().assign_user(request.user):
            return HttpResponseForbidden()
        invitation.delete()
        return HttpResponse('OK')

    def put(self, request, pk):
        """ Return data of features """
        invitation = get_object_or_404(UserOrganisationInvitation, pk=pk)
        if not invitation.organisation.has_permission().assign_user(request.user):
            return HttpResponseForbidden()
        invitation.role = UserRole.objects.get(id=request.data.get('role', 0))
        invitation.save()
        return HttpResponse('OK')


class UserOrganisationInvitationAccept(APIView):
    """
    Method to accept the invitation
    """

    def get(self, request, uuid):
        invitation = get_object_or_404(
            UserOrganisationInvitation, uuid=uuid)
        if not request.user.is_authenticated or invitation.email != request.user.email:
            return redirect(
                reverse('user-organisation-invitation-login', args=[uuid])
            )
        invitation.accept(request.user)
        url = reverse(
            'organisation_detail',
            args=[invitation.organisation.pk]) + '#profile'
        return redirect(url)


class UserOrganisationInvitationReject(APIView):
    """
    Method to reject the invitation
    """

    def get(self, request, uuid):
        invitation = get_object_or_404(
            UserOrganisationInvitation, uuid=uuid)
        invitation.reject()
        return HttpResponse('Rejected')


class OrganisationSchedulerList(APIView):
    """
    Scheduler list of organisation
    """

    def get(self, request, pk):
        org = get_object_or_404(Organisation, pk=pk)
        data = {
            'templates': SchedulerTemplateSerializer(
                SchedulerTemplate.objects.all(), many=True).data,
            'data': SchedulerOrganisationSerializer(
                org.schedulerorganisation_set.all(), many=True).data
        }
        return Response(data)


class OrganisationCreateScheduler(APIView):
    """
    Create scheduler
    """

    def post(self, request, pk):
        org = get_object_or_404(Organisation, pk=pk)
        form = ScheduledTicketForm(
            request.data,
            assigned_to_choices=org.operators)
        if form.is_valid():
            SchedulerOrganisation.create_from_form(
                form, org, request.user
            )
            url = reverse(
                'organisation_detail',
                args=[org.pk]) + '#work-order-scheduler'
            return redirect(url)
        else:
            # TODO: LIT
            #  fix this by returning form
            return HttpResponseBadRequest('Some data is invalid')


class OrganisationEditScheduler(APIView):
    """
    Edit scheduler
    """

    def post(self, request, pk, schedule_pk):
        org = get_object_or_404(Organisation, pk=pk)
        try:
            schedule = org.schedulerorganisation_set.get(id=schedule_pk)
            form = ScheduledTicketForm(
                request.data,
                assigned_to_choices=org.operators)
            if form.is_valid():
                schedule.edit_from_form(form, user=request.user)
                url = reverse(
                    'organisation_detail',
                    args=[org.pk]) + '#work-order-scheduler'
                return redirect(url)
            else:
                # TODO: LIT
                #  fix this by returning form
                return HttpResponseBadRequest('Some data is invalid')
        except SchedulerOrganisation.DoesNotExist:
            url = reverse(
                'organisation_detail',
                args=[org.pk]) + '#work-order-scheduler'
            return redirect(url)


class OrganisationSchedulerActivate(APIView):
    """
    Active scheduler
    """

    def post(self, request, pk, schedule_pk):
        org = get_object_or_404(Organisation, pk=pk)
        try:
            schedule = org.schedulerorganisation_set.get(id=schedule_pk)
            schedule.activate()
            url = reverse(
                'organisation_detail',
                args=[org.pk]) + '#work-order-scheduler'
            return redirect(url)
        except SchedulerOrganisation.DoesNotExist:
            url = reverse(
                'organisation_detail',
                args=[org.pk]) + '#work-order-scheduler'
            return redirect(url)


class OrganisationSchedulerInactivate(APIView):
    """
    Inactive scheduler
    """

    def post(self, request, pk, schedule_pk):
        org = get_object_or_404(Organisation, pk=pk)
        try:
            schedule = org.schedulerorganisation_set.get(id=schedule_pk)
            schedule.inactivate()
            url = reverse(
                'organisation_detail',
                args=[org.pk]) + '#work-order-scheduler'
            return redirect(url)
        except SchedulerOrganisation.DoesNotExist:
            url = reverse(
                'organisation_detail',
                args=[org.pk]) + '#work-order-scheduler'
            return redirect(url)




