__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '18/03/21'

from django.contrib import admin

from amlit.forms.organisation import OrganisationForm
from amlit.models import (
    Organisation, UserOrganisation, UserOrganisationInvitation,
    UserRole, RolePermission
)


class UserOrganisationInline(admin.TabularInline):
    model = UserOrganisation
    extra = 1


class UserOrganisationInvitationInline(admin.TabularInline):
    model = UserOrganisationInvitation
    extra = 1


class OrganisationFormAdmin(OrganisationForm):
    class Meta:
        model = Organisation
        fields = '__all__'


class OrganisationAdmin(admin.ModelAdmin):
    list_display = (
        'name', 'owner', 'community_code', 'created_at')
    inlines = (UserOrganisationInline, UserOrganisationInvitationInline)
    form = OrganisationFormAdmin


class UserRoleAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')
    filter_horizontal = ('permissions',)


class RolePermissionAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')


admin.site.register(Organisation, OrganisationAdmin)
admin.site.register(UserRole, UserRoleAdmin)
admin.site.register(RolePermission, RolePermissionAdmin)
