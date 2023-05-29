__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '05/03/21'

from django.contrib.postgres.fields import ArrayField
from django.db import models
from django.utils.translation import ugettext_lazy as _
from civitas.models.feature.feature_base import FeatureBase
from helpdesk.models import Ticket


class FeatureTicket(models.Model):
    """
    One on one with ticket to have features data and additional data from civitas
    """
    ticket = models.OneToOneField(
        Ticket,
        on_delete=models.CASCADE,
        verbose_name=_('ticket')
    )
    features = ArrayField(
        models.IntegerField(),
        help_text="List of feature ID for a ticket",
        null=True, blank=True
    )
    community_code = models.CharField(
        _('community code'),
        max_length=128,
        null=True, blank=True,
        help_text=_('Community for this ticket')
    )

    def __str__(self):
        return self.ticket.__str__()

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        self.assign_community_code()

    def assign_community_code(self):
        """ assign community code to ticket"""
        if not self.community_code:
            for feature in self.features:
                try:
                    code = FeatureBase.objects.get(id=feature).system.community.code
                    self.community_code = code
                    self.save()
                    return
                except (FeatureBase.DoesNotExist, AttributeError):
                    pass

    @property
    def recurring_ticket(self):
        """ Return recurring ticket for this feature ticket"""
        from amlit_helpdesk.models.recurring_ticket import RecurringTicket
        try:
            return self.ticket.original_ticket
        except RecurringTicket.DoesNotExist:
            return RecurringTicket.objects.filter(tickets__in=[self.id]).first()

    @property
    def recurring_type(self):
        recurring_ticket = self.recurring_ticket
        if recurring_ticket:
            return recurring_ticket.recurring_type
        else:
            return '-'

    @property
    def next_date(self):
        recurring_ticket = self.recurring_ticket
        if recurring_ticket:
            return recurring_ticket.next_date
        else:
            return '-'
