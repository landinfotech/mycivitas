__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '08/03/21'

from django.db.models import Q
from django.http import JsonResponse
from django.shortcuts import get_object_or_404

from rest_framework.generics import ListAPIView
from rest_framework.views import APIView

from amlit_helpdesk.models.feature_ticket import FeatureTicket
from civitas.models.community import Community
from civitas.models.feature.feature_geometry import FeatureBase
from civitas.permissions import CommunityAccessPermission
from civitas.serializer.features import FeatureGeometryGeoSerializer
from helpdesk.serializers import DatatablesTicketSerializer
from helpdesk.models import Ticket


class AmlitDatatablesTicketSerializer(DatatablesTicketSerializer):
    class Meta:
        model = Ticket
        # fields = '__all__'
        fields = ('ticket', 'id', 'priority', 'title', 'queue', 'status',
                  'created', 'due_date', 'assigned_to', 'submitter', 'row_class',
                  'time_spent', 'kbitem', 'description')


class TicketListView(ListAPIView):
    """
    Return of tickets list of community
    """

    serializer_class = AmlitDatatablesTicketSerializer
    model = serializer_class.Meta.model
    paginate_by = 100

    def get_queryset(self):
        queryset = FeatureTicket.objects.values_list('ticket', flat=True)
        queryset = self.model.objects.filter(id__in=queryset)
        return queryset.order_by('-created')


class FeatureTicketListView(ListAPIView):
    """
    Return of tickets list of feature
    """

    serializer_class = AmlitDatatablesTicketSerializer
    model = serializer_class.Meta.model
    paginate_by = 100

    def get_queryset(self):
        feature_id = self.kwargs['id']
        queryset = FeatureTicket.objects.filter(
            features__contains=[feature_id]).values_list('ticket', flat=True)
        queryset = self.model.objects.filter(
            id__in=queryset).filter(
            status__in=[Ticket.OPEN_STATUS, Ticket.REOPENED_STATUS, Ticket.NEW_STATUS])
        return queryset.order_by('-created')


class FeatureTicketFeatureDetailAPI(APIView):
    """
    Return Detail Asset of ticket
    """

    def get(self, request, id, *args):
        feature_ticket = get_object_or_404(FeatureTicket, ticket_id=id)
        features = FeatureBase.objects.filter(id__in=feature_ticket.features)
        return JsonResponse({
            'features': FeatureGeometryGeoSerializer(features, many=True).data,
            'recurring_type': feature_ticket.recurring_type,
            'next_date': feature_ticket.next_date
        })


class CommunityTicketAPI(APIView):
    """
    Return ticket list of community
    """
    permission_classes = (CommunityAccessPermission,)

    def get(self, request, pk):
        """ Return data of features """
        community = get_object_or_404(
            Community, pk=pk
        )
        queryset = FeatureTicket.objects.filter(
            community_code=community.code).values_list(
            'ticket', flat=True)
        queryset = Ticket.objects.filter(
            id__in=queryset).filter(
            Q(status=Ticket.NEW_STATUS) | Q(status=Ticket.OPEN_STATUS) | Q(status=Ticket.REOPENED_STATUS)
        ).order_by('-created')
        return JsonResponse(
            AmlitDatatablesTicketSerializer(queryset, many=True).data, safe=False
        )
