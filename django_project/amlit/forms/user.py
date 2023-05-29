from django import forms
from django.contrib.auth.forms import UserCreationForm
from amlit.models.user import User


class EditPasswordForm(UserCreationForm):
    class Meta:
        model = User
        fields = ('password1', 'password2')


class EditAvatarForm(forms.ModelForm):
    class Meta:
        model = User
        fields = ('avatar',)


class EditProfileForm(forms.ModelForm):
    class Meta:
        model = User
        fields = ('first_name', 'last_name', 'phone')
