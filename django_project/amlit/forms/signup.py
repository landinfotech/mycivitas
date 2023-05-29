from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.utils.translation import ugettext_lazy as _

from amlit.forms.organisation import OrganisationForm
from amlit.models.organisation import Organisation
from amlit.models.user import User
from civitas.models.community import Province

COUNTRY_CHOICES = (
    ('CA', 'Canada'),
)


class SignUpUserForm(UserCreationForm):
    first_name = forms.CharField(
        label=_("First name"),
        required=True,
    )
    billing_province = forms.ChoiceField(
        label=_("Billing province"),
        required=True
    )
    billing_country = forms.ChoiceField(
        label=_("Billing country"),
        required=True,
        choices=COUNTRY_CHOICES
    )

    class Meta:
        model = User
        fields = ("email", "first_name", 'last_name', 'password1', 'password2',
                  "billing_province", "billing_country")

    def __init__(self, *args, **kwargs):
        super(SignUpUserForm, self).__init__(*args, **kwargs)
        self.fields['billing_province'].choices = [
            (province.code, province.name)
            for province in Province.objects.all().order_by('name')
        ]


class SignUpUserFormWithInvitation(SignUpUserForm):
    def __init__(self, *args, **kwargs):
        super(SignUpUserFormWithInvitation, self).__init__(*args, **kwargs)
        self.fields['email'].widget.attrs['disabled'] = True


class SignUpOrganisationForm(OrganisationForm):
    class Meta:
        model = Organisation
        fields = (
            'community_code', 'name')
