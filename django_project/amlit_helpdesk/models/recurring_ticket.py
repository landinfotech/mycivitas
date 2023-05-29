__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '05/03/21'

import typing
from copy import deepcopy
from datetime import date
from django.db import models
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from dateutil.relativedelta import relativedelta
from helpdesk.models import Ticket
from amlit.models.preferences import SitePreferences
from amlit_helpdesk.models import FeatureTicket


class RecurringTicket(models.Model):
    """
    Recurring info for the ticket
    Contains all of tickets that already created
    And also create ticket automatically
    """
    original_ticket = models.OneToOneField(
        Ticket, on_delete=models.CASCADE,
        related_name='original_ticket'
    )
    last_ticket = models.OneToOneField(
        Ticket, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='last_ticket'
    )
    tickets = models.ManyToManyField(
        Ticket, null=True, blank=True
    )
    STATUS_CAN_RECURRING_CREATED = [
        Ticket.OPEN_STATUS, Ticket.REOPENED_STATUS, Ticket.NEW_STATUS
    ]

    WEEKLY_FROM_TODAY = 'Weekly from today'
    MONTHLY_FROM_TODAY = 'Monthly from today'
    YEARLY_FROM_TODAY = 'Yearly from today'
    RECURRING_FROM_TODAY = [WEEKLY_FROM_TODAY, MONTHLY_FROM_TODAY, YEARLY_FROM_TODAY]

    WEEKLY_FROM_START_DATE = 'Weekly from start date'
    MONTHLY_FROM_START_DATE = 'Monthly from start date'
    YEARLY_FROM_START_DATE = 'Yearly from start date'
    RECURRING_FROM_START_DATE = [
        WEEKLY_FROM_START_DATE, MONTHLY_FROM_START_DATE, YEARLY_FROM_START_DATE]

    RECURRING_TIMEDELTA = {
        WEEKLY_FROM_TODAY: relativedelta(weeks=1),
        MONTHLY_FROM_TODAY: relativedelta(months=1),
        YEARLY_FROM_TODAY: relativedelta(years=1),

        WEEKLY_FROM_START_DATE: relativedelta(weeks=1),
        MONTHLY_FROM_START_DATE: relativedelta(months=1),
        YEARLY_FROM_START_DATE: relativedelta(years=1)
    }
    recurring_type = models.CharField(
        max_length=512
    )
    next_date = models.DateTimeField(
        null=True, blank=True
    )
    active = models.BooleanField(
        default=True,
        help_text="If it is active, it will always create the new ticket. "
                  "Make inactive to stop it to create ticket temporary. "
    )
    DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    MONTHS = ["January", "February", "Marc", "April", "May", "July", "June",
              "August", "September", "October", "November", "December"]

    def calculate_next_date(self):
        """ For calculating new date based on the recurring type """
        now = timezone.now()
        next_date = self.last_ticket.created
        try:
            timedelta = self.RECURRING_TIMEDELTA[self.recurring_type]
            if self.recurring_type in self.RECURRING_FROM_START_DATE and self.last_ticket.start_date:
                next_date = self.last_ticket.start_date + timedelta

            while next_date < now:
                next_date = next_date + timedelta

            return next_date
        except KeyError:
            recurring_types_splitted = self.recurring_type.strip().split(' ')
            period = recurring_types_splitted[0]
            try:
                # for weekly
                if period == 'Weekly':
                    day = recurring_types_splitted[len(recurring_types_splitted) - 1].strip()
                    idx_day = self.DAYS.index(day)

                    # shift to next week day
                    timedelta = relativedelta(days=1)
                    while next_date.weekday() != idx_day:
                        next_date = next_date + timedelta

                    # shift to next week if it is the past
                    timedelta = relativedelta(weeks=1)
                    while next_date < now:
                        next_date = next_date + timedelta
                    return next_date

                # For monthly
                elif period == 'Monthly':
                    raw_day = recurring_types_splitted[len(recurring_types_splitted) - 1].strip('#')
                    day = int(raw_day)
                    if day < 1:
                        day = 1
                    if day > 31:
                        day = 31
                    try:
                        next_date = next_date.replace(day=day)
                    except ValueError:
                        day = 30
                        next_date = next_date.replace(day=day)

                    # shift to next week if it is the past
                    timedelta = relativedelta(months=1)
                    while next_date < now:
                        next_date = next_date + timedelta

                    # we replace the correct one
                    if next_date.day != int(raw_day):
                        recurring_types_splitted[len(recurring_types_splitted) - 1] = f'#{next_date.day}'
                        self.recurring_type = ' '.join(recurring_types_splitted)
                        self.save()
                    return next_date

                # For yearly
                elif period == 'Yearly':
                    day = recurring_types_splitted[len(recurring_types_splitted) - 2]
                    month = self.MONTHS.index(recurring_types_splitted[len(recurring_types_splitted) - 1]) + 1
                    next_date = next_date.replace(day=int(day), month=int(month))

                    # shift to next week if it is the past
                    timedelta = relativedelta(years=1)
                    while next_date < now:
                        next_date = next_date + timedelta
                    return next_date

            except (KeyError, ValueError):
                pass

            return None

    def setup_data(self, ticket: Ticket = None):
        """ Setup recurring data """
        changed = False
        if not self.last_ticket:
            ticket = self.original_ticket
            changed = True

        if ticket and self.last_ticket != ticket:
            self.last_ticket = ticket
            self.tickets.add(self.last_ticket)
            changed = True

        # check next date
        next_date = self.calculate_next_date()
        if next_date and next_date != self.next_date:
            self.next_date = next_date
            changed = True
        if changed:
            self.save()

    @staticmethod
    def create_recurring(ticket: Ticket, recurring_type: str) -> (typing.Optional["RecurringTicket"], bool):
        """ Create recurring for the ticket"""
        pref = SitePreferences.preferences()
        if ticket.queue.id in pref.recurred_queues_ids:
            return RecurringTicket.objects.get_or_create(
                original_ticket=ticket,
                defaults={
                    'recurring_type': recurring_type
                }
            )
        return None, False

    def check_recurring_event(self):
        """ Recurring event for creating new ticket next_date is today
        """
        print(f'Check recurring for {self.original_ticket.__str__()}')
        if self.active:
            if date.today() >= self.next_date.date():
                if self.last_ticket.status not in self.STATUS_CAN_RECURRING_CREATED:
                    self._create_new_ticket()
                else:
                    print('Old ticket is still opened')
            pass

    def _create_new_ticket(self):
        """ Create new ticket for last event """
        last_ticket = self.last_ticket

        new_ticket = deepcopy(last_ticket)
        new_ticket.id = None
        new_ticket.status = Ticket.NEW_STATUS

        last_created_date = last_ticket.created
        if self.recurring_type in self.RECURRING_FROM_START_DATE and self.last_ticket.start_date:
            last_created_date = self.last_ticket.start_date
        new_ticket.created = self.next_date

        # due date is based on how many days from created and due date
        if last_ticket.start_date:
            new_ticket.start_date = new_ticket.created + (
                    last_ticket.start_date - last_created_date)
        if last_ticket.due_date:
            new_ticket.due_date = new_ticket.created + (
                    last_ticket.due_date - last_created_date)
        new_ticket.save()

        try:
            feature_ticket = self.last_ticket.featureticket
            new_feature_ticket = deepcopy(feature_ticket)
            new_feature_ticket.id = None
            new_feature_ticket.ticket = new_ticket
            new_feature_ticket.save()
        except FeatureTicket.DoesNotExist:
            pass
        self.setup_data(new_ticket)

    @staticmethod
    def get_recurring(ticket: Ticket):
        try:
            return ticket.last_ticket
        except RecurringTicket.DoesNotExist:
            return None

    @staticmethod
    def can_recurring(ticket: Ticket) -> bool:
        site_preferences = SitePreferences.load()
        try:
            return ticket.last_ticket is not None
        except RecurringTicket.DoesNotExist:
            try:
                return ticket.original_ticket is None
            except RecurringTicket.DoesNotExist:
                return site_preferences.recurred_queues.filter(id=ticket.queue.id).first() is not None


@receiver(post_save, sender=RecurringTicket)
def save_default(sender, instance: RecurringTicket, **kwargs):
    instance.setup_data()
