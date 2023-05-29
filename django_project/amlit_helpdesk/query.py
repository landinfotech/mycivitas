__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '27/08/21'

from helpdesk.query import (
    __Query__, get_search_filter_args
)
from model_utils import Choices
from helpdesk.models import Ticket
from amlit_helpdesk.serializer.ticket import DatatablesTicketExtendedSerializer
from amlit_helpdesk.models.feature_ticket import FeatureTicket

DATATABLES_ORDER_COLUMN_CHOICES = Choices(
    ('0', 'title'),
    ('1', 'queue__title'),
    ('2', 'priority'),
    ('3', 'status'),
    ('4', 'created'),
    ('5', 'assigned_to'),
    ('6', 'submitter_email'),
    ('7', 'start_date'),
    ('8', 'due_date')
)


def get_user_tickets(user):
    if user.is_staff:
        return Ticket.objects.all()

    tickets = FeatureTicket.objects.filter(
        community_code__in=user.userorganisation_set.values_list(
            'organisation__community_code', flat=True)
    ).values_list('ticket', flat=True)
    return Ticket.objects.filter(id__in=tickets)


class Query(__Query__):
    def get_datatables_context(self, **kwargs):
        """
        This function takes in a list of ticket objects from the views and throws it
        to the datatables on ticket_list.html. If a search string was entered, this
        function filters existing dataset on search string and returns a filtered
        filtered list. The `draw`, `length` etc parameters are for datatables to
        display meta data on the table contents. The returning queryset is passed
        to a Serializer called DatatablesTicketSerializer in serializers.py.
        """
        objects = self.get()
        if not self.huser.user.is_staff:
            tickets = FeatureTicket.objects.filter(
                community_code__in=self.huser.user.userorganisation_set.values_list(
                    'organisation__community_code', flat=True)
            ).values_list('ticket', flat=True)
            objects = objects.filter(id__in=tickets)
        order_by = '-created'
        draw = int(kwargs.get('draw', [0])[0])
        length = int(kwargs.get('length', [25])[0])
        start = int(kwargs.get('start', [0])[0])
        search_value = kwargs.get('search[value]', [""])[0]
        order_column = kwargs.get('order[0][column]', ['5'])[0]
        order = kwargs.get('order[0][dir]', ["asc"])[0]

        order_column = DATATABLES_ORDER_COLUMN_CHOICES[order_column]
        # django orm '-' -> desc
        if order == 'desc':
            order_column = '-' + order_column

        queryset = objects.all().order_by(order_by)
        total = queryset.count()

        if search_value:  # Dead code currently
            queryset = queryset.filter(get_search_filter_args(search_value))

        count = queryset.count()
        queryset = queryset.order_by(order_column)[start:start + length]
        return {
            'data': DatatablesTicketExtendedSerializer(queryset, many=True).data,
            'recordsFiltered': count,
            'recordsTotal': total,
            'draw': draw
        }
