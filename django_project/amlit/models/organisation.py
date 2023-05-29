__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '22/01/21'

import uuid
from datetime import timedelta

from django.conf import settings
from django.contrib.gis.db import models
from django.contrib.sites.models import Site
from django.core.mail import send_mail
from django.db.models import Q
from django.shortcuts import reverse
from django.template.loader import render_to_string
from django.utils import timezone
from django.utils.translation import ugettext_lazy as _

from amlit.models.user import User
from civitas.models.community import Community
from core.models.term import TermModel


class OrganisationSubscriptionError(Exception):
    """Raised when organisation subscription error"""
    pass


class OrganisationByUser(models.Manager):
    def admin_role(self, user):
        """ Return organisation that user has admin roles
        :type user: User
        """
        organisations = list(UserOrganisation.objects.filter(
            user=user, role__name='Admin').values_list(
            'organisation_id', flat=True))
        return super().get_queryset().filter(
            Q(owner=user) | Q(id__in=organisations))

    def all_role(self, user):
        """ Return organisation that user has every roles
        :type user: User
        """
        organisations = list(UserOrganisation.objects.filter(
            user=user).values_list('organisation_id', flat=True))
        return super().get_queryset().filter(
            Q(owner=user) | Q(id__in=organisations))


class Organisation(TermModel):
    """
    Organisation that has management.
    Having users with their role.
    Also has the owner
    Organisation can just access specific community
    """

    owner = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        verbose_name=_('owner')
    )

    community_code = models.CharField(
        _('community code '),
        max_length=128,
        default='',
        unique=True,
        help_text=_('Community for this organisation')
    )

    objects = models.Manager()
    by_user = OrganisationByUser()

    # Created at
    created_at = models.DateTimeField(
        _('Created at '),
        default=timezone.now
    )

    @property
    def community_name(self):
        """ Return name of community"""
        try:
            return Community.objects.get(code=self.community_code)
        except Community.DoesNotExist:
            return ''

    @property
    def max_user(self):
        return 1

    @property
    def able_to_add_user(self):
        return True

    @property
    def users_count(self):
        return self.userorganisation_set.count() + self.userorganisationinvitation_set.count()

    def is_owner(self, user):
        """ Return user is owner role
        :type user: User
        """
        if self.owner == user:
            return True
        return False

    def is_admin(self, user):
        """ Return user is admin role
        :type user: User
        """
        if self.is_owner(user):
            return True
        try:
            return UserRole.ADMIN in UserOrganisation.objects.get(
                user=user, organisation=self).role.name
        except UserOrganisation.DoesNotExist:
            return False

    def role(self, user: User):
        """ Return role of user
        :type user: User
        """
        if self.is_owner(user):
            return UserRole.OWNER
        try:
            return UserOrganisation.objects.get(
                user=user, organisation=self).role.name
        except UserOrganisation.DoesNotExist:
            return UserRole.UNKNOWN

    def has_permission(self):
        """ Return the permissions interface
        """
        return _OrganisationPermissionsInterface(self)

    def save(self, *args, **kwargs):
        super(Organisation, self).save(*args, **kwargs)
        self.check_user_access()

    def check_user_access(self):
        """
        Check user access
        UserOrganisation and UserOrganisationInvitation are combined
        Delete UserOrganisationInvitation first if more than max user
        Delete older UserOrganisation if more than max user
        """

        # check the owner is the one of user organisation
        UserOrganisation.objects.get_or_create(
            user=self.owner,
            organisation=self,
            defaults={
                'role': UserRole.objects.filter(
                    permissions__name=RolePermission.ASSIGN_USER).first()
            }
        )

        access_counter = 1  # first is from the owner access
        user_org_set = self.userorganisation_set.exclude(
            user=self.owner).order_by('-pk')
        user_invitation_set = self.userorganisationinvitation_set.all().order_by(
            '-pk')
        for accesses in [user_org_set, user_invitation_set]:
            for access in accesses:
                access_counter += 1
                if access_counter > self.max_user:
                    access.delete()

    @property
    def operators(self):
        """
        Return the list of operators
        """
        return User.objects.filter(
            id__in=self.userorganisation_set.values_list('user', flat=True))

    @property
    def scheduler_templates(self) -> list:
        """
        Return scheduler data in list
        """
        from amlit_helpdesk.models import SchedulerTemplate
        from amlit_helpdesk.serializer.scheduler import \
            SchedulerTemplateSerializer
        return SchedulerTemplateSerializer(
            SchedulerTemplate.objects.all(), many=True).data

    @property
    def scheduler_data(self) -> list:
        """
        Return scheduler data in list
        """
        from amlit_helpdesk.serializer.scheduler import \
            SchedulerOrganisationSerializer
        return SchedulerOrganisationSerializer(
            self.schedulerorganisation_set.all(), many=True).data


# permissions interface
class _OrganisationPermissionsInterface:
    # Return permissions for the user in organisation
    def __init__(self, organisation: Organisation):
        self.organisation = organisation

    def _get_permission(self, user, permission: str):
        if not user:
            return False
        if user.is_staff or self.organisation.is_owner(user):
            return True
        else:
            user_organisation = self.organisation.userorganisation_set.filter(
                user=user).first()
            if user_organisation:
                return user_organisation.role.permissions.filter(
                    name=permission).first() is not None

        return False

    def view_map(self, user: User) -> bool:
        return self._get_permission(user, RolePermission.VIEW_MAP)

    def manage_access(self, user: User) -> bool:
        return self._get_permission(user, RolePermission.MANAGE_ACCESS)

    def assign_user(self, user: User) -> bool:
        return self._get_permission(user, RolePermission.ASSIGN_USER)

    def create_ticket(self, user: User) -> bool:
        return self._get_permission(user, RolePermission.CREATE_TICKET)

    def edit_ticket(self, user: User) -> bool:
        return self._get_permission(user, RolePermission.EDIT_TICKET)

    def comment_ticket(self, user: User) -> bool:
        return self._get_permission(user, RolePermission.COMMENT_TICKET)

    def delete_ticket(self, user: User) -> bool:
        return self._get_permission(user, RolePermission.DELETE_TICKET)


class RolePermission(TermModel):
    """
    Permissions for role
    """
    ASSIGN_USER = 'assign-user'
    MANAGE_ACCESS = 'manage-access'
    COMMENT_TICKET = 'comment-ticket'
    CREATE_TICKET = 'create-ticket'
    DELETE_TICKET = 'delete-ticket'
    EDIT_TICKET = 'edit-ticket'
    SEE_TICKET = 'see-ticket'
    VIEW_MAP = 'view-map'
    VIEW_REPORT = 'view-report'


class UserRole(TermModel):
    """
    Role for user in organisation
    """
    # TODO: LIT
    #  We need to focus this permissions into permissions
    ADMIN = 'Admin'
    OPERATOR = 'Operator'
    OWNER = 'Owner'
    UNKNOWN = 'Unknown'

    permissions = models.ManyToManyField(
        RolePermission,
        verbose_name=_('permissions'),
        blank=True
    )


class UserOrganisation(models.Model):
    """
    Model that link user with organisation with their role
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        verbose_name=_('user')
    )
    organisation = models.ForeignKey(
        Organisation,
        on_delete=models.CASCADE,
        verbose_name=_('organisation')
    )
    role = models.ForeignKey(
        UserRole,
        on_delete=models.CASCADE,
        verbose_name=_('role')
    )

    class Meta:
        unique_together = ('user', 'organisation')

    def save(self, *args, **kwargs):
        super(UserOrganisation, self).save(*args, **kwargs)
        self.organisation.check_user_access()

    def delete(self, using=None, keep_parents=False):
        """
        When user organisation deleted, we need to notify user
        """
        super(UserOrganisation, self).delete(using, keep_parents)
        # TODO: LIT
        #  Create notification for the user


class UserOrganisationInvitation(models.Model):
    """
    Model that have invitation of user to organisation
    """
    uuid = models.UUIDField(
        unique=True,
        default=uuid.uuid4,
        help_text=('Unique id for the invitation',)
    )
    email = models.EmailField(
        _('email address')
    )
    organisation = models.ForeignKey(
        Organisation,
        on_delete=models.CASCADE,
        verbose_name=_('organisation')
    )
    role = models.ForeignKey(
        UserRole,
        on_delete=models.CASCADE,
        verbose_name=_('role')
    )

    class Meta:
        unique_together = ('email', 'organisation')

    def save(self, *args, **kwargs):
        super(UserOrganisationInvitation, self).save(*args, **kwargs)
        self.organisation.check_user_access()
        try:
            self.send_invitation()
        except Exception:
            pass

    @property
    def accept_link(self):
        domain = ''
        try:
            domain = Site.objects.get(id=settings.SITE_ID).name.strip('/')
        except Site.DoesNotExist:
            pass
        return domain + reverse('user-organisation-invitation-accept',
                                args=[self.uuid])

    @property
    def reject_link(self):
        domain = ''
        try:
            domain = Site.objects.get(id=settings.SITE_ID).name.strip('/')
        except Site.DoesNotExist:
            pass
        return domain + reverse('user-organisation-invitation-reject',
                                args=[self.uuid])

    def accept(self, user):
        """
        Accept invitation by user
        The user needs to be same with email
        :type user: User
        """
        if user.email == self.email:
            self.delete()
            UserOrganisation.objects.get_or_create(
                user=user,
                organisation=self.organisation,
                defaults={
                    'role': self.role
                }
            )

    def reject(self):
        """
        Reject invitation by user
        """
        self.delete()

    def send_invitation(self):
        """ Send email for this notification """
        send_mail(
            subject='{} You are invited to {}'.format(
                settings.EMAIL_SUBJECT_PREFIX, self.organisation.name),
            message=render_to_string(
                'pages/invitation/invitation_template.html', {
                    'object': self
                }),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[self.email],
            fail_silently=False,
        )
