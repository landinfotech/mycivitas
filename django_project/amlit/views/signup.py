import json

from django.conf import settings
from django.contrib.auth import get_user_model, authenticate, login
from django.db import ProgrammingError
from django.http import HttpResponseRedirect, JsonResponse
from django.shortcuts import render, reverse, redirect
from django.views.generic import View

from amlit.forms.signup import SignUpOrganisationForm, SignUpUserForm


User = get_user_model()

class _SignUpView(View):
    """ Abstract class for signup view"""

    def get_forms(self) -> (SignUpUserForm, SignUpOrganisationForm):
        """ Return form from the request """
        user_form = SignUpUserForm()
        organisation_form = SignUpOrganisationForm()
        try:
            data = self.request.session['signup']
            user_form = SignUpUserForm(data)
            organisation_form = SignUpOrganisationForm(data)
        except KeyError:
            pass
        return user_form, organisation_form


class SignUpView(_SignUpView):
    """ Showing sign up view form
    """
    template_name = 'registration/signup.html'

    def get_context(self, user_form, organisation_form):
        return {
            'user_form': user_form,
            'organisation_form': organisation_form
        }

    def get(self, request, *args, **kwargs):
        try:
            user_form, organisation_form = self.get_forms()
            return render(
                request, 'registration/signup.html',
                self.get_context(
                    user_form, organisation_form)
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

    def post(self, request, *args, **kwargs):
        self.request.session['signup'] = request.POST
        user_form, organisation_form = self.get_forms()
        if user_form.is_valid() and organisation_form.is_valid():
            new_user = user_form.save()
            organisation_form.instance.owner = new_user
            organisation = organisation_form.save()
            new_user = authenticate(
                username=user_form.cleaned_data[User.USERNAME_FIELD],
                password=user_form.cleaned_data['password1'],
            )
            login(request, new_user)
            return redirect(
                reverse(
                    'organisation_signup_complete',
                    args=(organisation.pk,)))

        return HttpResponseRedirect(reverse('signup'))


class SignUpSubscriptionView(_SignUpView):
    """ Showing subscription view on sign up
    """

    def get(self, request, *args, **kwargs):
        redirect_url = reverse('signup')
        # check the session data for signup
        if 'signup' not in self.request.session:
            return HttpResponseRedirect(redirect_url)
        user_form, organisation_form = self.get_forms()
        if not user_form.is_valid() or not organisation_form.is_valid():
            return HttpResponseRedirect(redirect_url)

        return render(
            request, 'registration/signup-subscription.html', {
                'billing_name': '{} {}'.format(
                    user_form.instance.first_name, user_form.instance.last_name
                ),
                'billing_email': user_form.instance.email,
                'url_submit': reverse('signup-subscription'),
            }
        )

    def post(self, request, *args, **kwargs):
        user_form, organisation_form = self.get_forms()
        if user_form.is_valid() and organisation_form.is_valid():
            new_user = user_form.save()
            organisation_form.instance.owner = new_user
            organisation = organisation_form.save()
            new_user = authenticate(
                username=user_form.cleaned_data[User.USERNAME_FIELD],
                password=user_form.cleaned_data['password1'],
            )
            login(request, new_user)

            # subscription data
            data = json.loads(request.body)
            data.update(user_form.cleaned_data)
            try:
                organisation.subscribe(new_user, data)
                return JsonResponse({'Result': 'OK', 'URL': reverse(
                    'organisation_signup_complete', args=(organisation.pk,))})
            except Exception as e:
                return JsonResponse({'error': (e.args[0])}, status=403)
        return HttpResponseRedirect(reverse('signup'))
