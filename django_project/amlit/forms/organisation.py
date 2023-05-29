__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '18/03/21'

import json
from django import forms
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.utils.translation import ugettext_lazy as _
from amlit.models.organisation import (
    Organisation, UserOrganisation, UserOrganisationInvitation, UserRole
)
from civitas.models.community import Community

User = get_user_model()


class OrganisationForm(forms.ModelForm):
    name = forms.CharField(
        label=_('Organisation name'),
        required=False,
        help_text='Keep this empty will fill the same name with community.',
    )
    community_code = forms.ModelChoiceField(
        Community.objects.all(),
        label=_('Community')
    )

    class Meta:
        model = Organisation
        fields = (
            'name', 'description', 'owner', 'community_code')

    def __init__(self, *args, **kwargs):
        super(OrganisationForm, self).__init__(*args, **kwargs)
        codes = list(Organisation.objects.values_list('community_code', flat=True))
        if self.instance.id:
            codes.remove(self.instance.community_code)
            try:
                community = Community.objects.get(
                    code=self.instance.community_code)
                self.fields['community_code'].initial = community
                self.initial['community_code'] = community
            except Community.DoesNotExist:
                pass
        self.fields['community_code'].choices = [(c.id, c.__str__()) for c in Community.objects.exclude(
            code__in=codes
        ).order_by('name')]

    def clean(self):
        cleaned_data = self.cleaned_data
        community = cleaned_data.get('community_code', None)
        if community:
            cleaned_data['community_code'] = community.code

        name = self.cleaned_data['name']
        try:
            if not name:
                if not community:
                    raise ValidationError('Community is required')
                name = community.name
            Organisation.objects.exclude(pk=self.instance.pk).get(name=name)
            raise ValidationError('This organisation name already exist')
        except Organisation.DoesNotExist:
            pass
        self.cleaned_data['name'] = name
        return cleaned_data


class OrganisationCreateForm(OrganisationForm):
    class Meta:
        model = Organisation
        fields = (
            'community_code', 'name', 'description')

    def __init__(self, *args, **kwargs):
        super(OrganisationCreateForm, self).__init__(*args, **kwargs)


class UserOrganisationForm(forms.ModelForm):
    class Meta:
        model = UserOrganisation
        fields = ('id', 'user', 'organisation', 'role')

    def __init__(self, *args, **kwargs):
        super(UserOrganisationForm, self).__init__(*args, **kwargs)
        self.fields['role'].choices = [
            (c.id, c.name) for c in UserRole.objects.all()]
        try:
            instance = kwargs['instance']
            initial = kwargs['initial']
            self.fields['user'].widget.attrs['disabled'] = True
            if instance.organisation.owner.id == initial['user']:
                self.fields['role'].widget.attrs['disabled'] = True

        except KeyError:
            pass


class UserOrganisationInvitationForm(forms.ModelForm):
    class Meta:
        model = UserOrganisationInvitation
        fields = ('email', 'role')

    def __init__(self, *args, **kwargs):
        super(UserOrganisationInvitationForm, self).__init__(*args, **kwargs)
        self.fields['role'].choices = [
            (c.id, c.name) for c in UserRole.objects.all()]
        self.fields['email'].widget.attrs['disabled'] = True
