__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '18/03/21'

from django.conf import settings
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models
from django.utils.translation import ugettext_lazy as _
from phone_field import PhoneField
from core.models.term import TermModel


class UserTitle(TermModel):
    """
    Contains title of an user specification
    """
    name = models.CharField(
        _('title'), max_length=512, unique=True)

    def __str__(self):
        return self.name


class UserManager(BaseUserManager):
    """Define a model manager for User model with no username field."""

    use_in_migrations = True

    def _create_user(self, email, password, **extra_fields):
        """Create and save a User with the given email and password."""
        if not email:
            raise ValueError('The given email must be set')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email, password=None, **extra_fields):
        """Create and save a regular User with the given email and password."""
        extra_fields.setdefault('is_staff', False)
        extra_fields.setdefault('is_superuser', False)
        return self._create_user(email, password, **extra_fields)

    def create_superuser(self, email, password, **extra_fields):
        """Create and save a SuperUser with the given email and password."""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self._create_user(email, password, **extra_fields)


class User(AbstractUser):
    """
    Users within the Django authentication system are represented by this model.

    Username and password are required. Other fields are optional.
    We make username as email format
    """

    username = None
    email = models.EmailField(
        _('email address'), unique=True
    )

    title = models.ForeignKey(
        UserTitle,
        null=True, blank=True,
        on_delete=models.SET_NULL,
        verbose_name=_('title')
    )
    phone = PhoneField(
        blank=True, help_text=_('Contact phone number')
    )
    avatar = models.ImageField(
        upload_to="avatar", blank=True
    )

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    objects = UserManager()

    def __str__(self):
        if self.first_name or self.last_name:
            return self.get_username() + ' ({})'.format(' '.join([self.first_name, self.last_name]))
        else:
            return self.get_username()

    @property
    def organisations_as_admin(self):
        """ Return organisation that has admin role or owner """
        from amlit.models.organisation import Organisation
        return Organisation.by_user.admin_role(self)

    @property
    def organisations(self):
        """ Return organisations that user have access to """
        from amlit.models.organisation import Organisation
        return Organisation.by_user.all_role(self)

    @property
    def communities(self):
        """ Return communities that user have access to  """
        from civitas.models.community import Community
        queryset = Community.objects.all()
        if not self.is_staff:
            cummonity_codes = list(self.organisations.values_list(
                'community_code', flat=True))
            queryset = queryset.filter(code__in=cummonity_codes)
        return queryset

    @property
    def avatar_url(self) -> str:
        """ return avatar url """
        if self.avatar:
            return self.avatar.url
        return settings.STATIC_URL + 'img/no-profile.png'


class UserByString:
    user = None
    username = None

    def __init__(self, username):
        self.username = username
        try:
            self.user = User.objects.get(**{'{}'.format(User.USERNAME_FIELD): username})
        except User.DoesNotExist:
            pass

    def __str__(self):
        if self.user:
            return self.user.__str__()
        return self.username

    def full_str(self):
        """ return __str__ """
        return self.__str__()

    @property
    def avatar_url(self) -> str:
        """ return avatar url """
        if self.user:
            return self.user.avatar_url
        return settings.STATIC_URL + 'img/no-profile.png'
