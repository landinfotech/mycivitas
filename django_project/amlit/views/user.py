__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '22/01/21'

from django.contrib.auth import get_user_model
from django.contrib.auth.mixins import LoginRequiredMixin
from django.forms.models import model_to_dict
from django.shortcuts import render, get_object_or_404, reverse, redirect
from django.views.generic import View
from amlit.models.organisation import Organisation
from amlit.forms.user import (
    EditPasswordForm, EditAvatarForm, EditProfileForm
)

User = get_user_model()


class UserDetailView(View):
    """ Showing User Profile
    """
    model = User
    template_name = 'pages/user/profile.html'

    def get(self, request, username, *args, **kwargs):
        user = get_object_or_404(User, **{User.USERNAME_FIELD: username})
        return render(
            request, self.template_name, context={
                'object': user,
                'organisations': Organisation.by_user.all_role(user)
            }
        )


class UserSettingsView(LoginRequiredMixin, View):
    """ Showing User Settings
    """
    model = User
    template_name = 'pages/user/settings.html'

    def get_forms(self) -> (EditProfileForm, EditAvatarForm, EditPasswordForm):
        """ Return form from the request """
        edit_profile = EditProfileForm(initial=model_to_dict(self.request.user))
        edit_avatar = EditAvatarForm()
        edit_password = EditPasswordForm()
        try:
            data = self.request.session['settings']
            if data.get('password1', None):
                edit_password = EditPasswordForm(
                    data, instance=self.request.user)
            elif data.get('first_name', None):
                edit_profile = EditProfileForm(
                    data, instance=self.request.user)
        except KeyError:
            pass
        return edit_profile, edit_avatar, edit_password

    def get_context_view(self):
        edit_profile, edit_avatar, edit_password = self.get_forms()
        return {
            'object': self.request.user,
            'edit_password': edit_password,
            'edit_avatar': edit_avatar,
            'edit_profile': edit_profile
        }

    def get(self, request, *args, **kwargs):
        return render(
            request, self.template_name, context=self.get_context_view()
        )

    def post(self, request, *args, **kwargs):
        self.request.session['settings'] = request.POST

        data = self.request.session['settings']
        hash_setting = ''

        # if it has password in POST
        if data.get('password1', None):
            hash_setting = 'edit-password'
            edit_password = EditPasswordForm(
                request.POST, instance=request.user)
            if edit_password.is_valid():
                edit_password.save()
                return redirect(reverse('login'))
        elif request.FILES.get('avatar', None):
            hash_setting = 'edit-avatar'
            edit_avatar = EditAvatarForm(
                request.POST, request.FILES, instance=request.user)
            if edit_avatar.is_valid():
                edit_avatar.save()
        elif data.get('first_name', None):
            hash_setting = 'edit-profile'
            edit_profile = EditProfileForm(
                request.POST, instance=request.user)
            if edit_profile.is_valid():
                edit_profile.save()

        return redirect(
            reverse(
                'user-settings'
            ) + '#{}'.format(hash_setting)
        )
