__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '05/03/21'

from django.contrib.auth import get_user_model
from django.db import models
from django.utils.translation import ugettext_lazy as _
from django.utils import timezone
from civitas.models.feature.identifier import FeatureTypeCombination
from civitas.models.feature.feature_base import FeatureBase

from amlit.models.preferences import SitePreferences
from amlit.models.organisation import Organisation
from amlit_helpdesk.models import RecurringTicket, FeatureTicket

User = get_user_model()


class SchedulerTemplate(models.Model):
    """
    Scheduler template to create or update the recurring ticket
    Mostly used for schedule ticket ofr multi assets
    """
    feature_type_combination = models.IntegerField(
        _('Feature type combination'),
        unique=True,
        help_text=_(
            'Feature type combination will be used for getting all of assets fall for it for new ticket.'
        )
    )
    recurring_type = models.CharField(
        max_length=512
    )
    title = models.CharField(
        max_length=512,
        help_text=_('The title for the ticket.')
    )
    description = models.TextField(
        _('Description'),
        help_text=_('The description for the ticket.')
    )

    @property
    def feature_type_combination_str(self):
        feature_type_obj = self.feature_type_combination_obj
        if feature_type_obj:
            return FeatureTypeCombination.objects.get(id=self.feature_type_combination).__str__()
        else:
            return 'Not found'

    @property
    def feature_type_combination_obj(self):
        try:
            return FeatureTypeCombination.objects.get(id=self.feature_type_combination)
        except FeatureTypeCombination.DoesNotExist:
            return None

    class Meta:
        ordering = ('feature_type_combination',)


class SchedulerOrganisation(models.Model):
    """
    Overridden scheduler for an organisation
    """
    feature_type_combination = models.IntegerField(
        _('Feature type combination'),
        help_text=_(
            'Feature type combination will be used for getting all of assets fall for it for new ticket.'
        )
    )
    organisation = models.ForeignKey(
        Organisation,
        on_delete=models.CASCADE
    )
    recurring_ticket = models.OneToOneField(
        RecurringTicket,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )

    class Meta:
        ordering = ('feature_type_combination',)

    @property
    def feature_type_combination_str(self):
        feature_type_obj = self.feature_type_combination_obj
        if feature_type_obj:
            return FeatureTypeCombination.objects.get(id=self.feature_type_combination).__str__()
        else:
            return 'Not found'

    @property
    def feature_type_combination_obj(self):
        try:
            return FeatureTypeCombination.objects.get(id=self.feature_type_combination)
        except FeatureTypeCombination.DoesNotExist:
            return None

    def activate(self):
        """ Activate the schedule"""
        recurring_ticket = self.recurring_ticket
        if recurring_ticket:
            recurring_ticket.active = True
            recurring_ticket.save()

    def inactivate(self):
        """ Inactivate the schedule"""
        recurring_ticket = self.recurring_ticket
        if recurring_ticket:
            recurring_ticket.active = False
            recurring_ticket.save()

    def update(self, data, user: User):
        """
        Update the scheduler based on data
        TODO: LIT
         We need to fix it to reuse function to create ticket, feature ticket and recurring ticket
        """
        from amlit_helpdesk.forms.ticket import AmlitTicketForm
        from amlit_helpdesk.views.ticket.update import update_ticket_data
        type_obj = self.feature_type_combination_obj
        if not type_obj:
            return

        preference = SitePreferences.load()
        data['queue'] = preference.recurred_queues.first().id

        features = FeatureBase.objects.filter(
            system__community__code=self.organisation.community_code,
            the_class=type_obj.the_class,
            sub_class=type_obj.sub_class,
            type=type_obj.type
        )
        recurring_ticket = self.recurring_ticket
        if not recurring_ticket:
            data['start_date'] = timezone.now()
            form = AmlitTicketForm(
                None,
                data,
                queue_choices=[(queue.id, queue.title) for queue in preference.recurred_queues.all()],
                assigned_to_choices=self.organisation.operators
            )
            if form.is_valid():
                ticket = form.save(user)
                feature_ticket = FeatureTicket.objects.create(
                    ticket=ticket,
                    features=list(features.values_list('id', flat=True))
                )
                recurring_ticket, created = RecurringTicket.create_recurring(
                    feature_ticket.ticket, form.data['recurring_type'])
                self.recurring_ticket = recurring_ticket
                self.save()
        else:
            ticket = recurring_ticket.last_ticket
            feature_ticket = ticket.featureticket
            feature_ticket.features = list(features.values_list('id', flat=True))
            feature_ticket.save()
            ticket.description = data['body']
            update_ticket_data(ticket, user, data)

    def edit_from_form(self, form, user: User):
        data = form.cleaned_data
        type_obj = data.get('feature_type_combination')
        if type_obj:
            self.feature_type_combination = type_obj
            self.save()
            self.update(
                {
                    'title': data.get('title'),
                    'body': data.get('description'),
                    'priority': 3,
                    'submitter_email': user.email,
                    'recurring_type': data.get('recurring_type'),
                    'assigned_to': data.get('assigned_to'),
                },
                user
            )
            return True
        return False

    @staticmethod
    def create_from_form(form, organisation: Organisation, user: User):
        data = form.cleaned_data
        type_obj = data.get('feature_type_combination')
        if type_obj:
            scheduler = SchedulerOrganisation.objects.create(
                feature_type_combination=type_obj,
                organisation=organisation
            )
            scheduler.update(
                {
                    'title': data.get('title'),
                    'body': data.get('description'),
                    'priority': 3,
                    'submitter_email': user.email,
                    'recurring_type': data.get('recurring_type'),
                    'assigned_to': data.get('assigned_to'),
                },
                user
            )
            return True
        return False
