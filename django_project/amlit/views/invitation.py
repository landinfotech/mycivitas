from amlit.models.organisation import UserOrganisationInvitation
from amlit.forms.signup import SignUpUserFormWithInvitation

from django.contrib.auth import get_user_model, authenticate, login
from django.contrib.auth.views import LoginView
from django.shortcuts import get_object_or_404, render, reverse, redirect
from django.views.generic import View, TemplateView

User = get_user_model()


class UserOrganisationInvitationPage(TemplateView):
    """
    View the invitation
    """
    template_name = "pages/invitation/invitation.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['object'] = get_object_or_404(
            UserOrganisationInvitation, uuid=self.kwargs['uuid'])
        return context


class UserOrganisationInvitationLogin(LoginView):
    """
    View to login from invitation
    """

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        get_object_or_404(
            UserOrganisationInvitation, uuid=self.kwargs['uuid'])
        context['signup_url'] = reverse('user-organisation-invitation-signup', args=[
            self.kwargs['uuid']])
        return context

    def get_success_url(self):
        return reverse(
            'user-organisation-invitation-accept',
            args=[self.kwargs['uuid']]
        )


class UserOrganisationInvitationSignup(View):
    """
    View to signup from invitation
    """
    form = SignUpUserFormWithInvitation
    template = 'pages/invitation/signup_with_invitation.html'

    def get(self, request, *args, **kwargs):
        invitation = get_object_or_404(
            UserOrganisationInvitation, uuid=self.kwargs['uuid'])
        return render(
            request, self.template,
            {
                'form': self.form(
                    initial={
                        'email': invitation.email
                    }
                )
            }
        )

    def post(self, request, *args, **kwargs):
        invitation = get_object_or_404(
            UserOrganisationInvitation, uuid=self.kwargs['uuid'])
        data = request.POST.copy()
        data['email'] = invitation.email
        form = self.form(data)
        if form.is_valid():
            form.save()
            new_user = authenticate(
                username=form.cleaned_data[User.USERNAME_FIELD],
                password=form.cleaned_data['password1'],
            )
            login(request, new_user)
            return redirect(self.get_success_url())
        return render(
            request, self.template,
            {
                'form': form
            }
        )

    def get_success_url(self):
        return reverse(
            'user-organisation-invitation-accept',
            args=[self.kwargs['uuid']]
        )
