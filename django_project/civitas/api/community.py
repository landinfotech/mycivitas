__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '11/11/20'

import csv
from django.core.paginator import Paginator
from django.shortcuts import get_object_or_404
from rest_framework.response import Response
from rest_framework.views import APIView
from django.http import HttpResponse, JsonResponse
from amlit.serializer.organisation import OrganisationSerializer
from civitas.models.community import Community
from civitas.models.view.reporter_data import ReporterData
from civitas.serializer.community import (
    CommunitySerializer, CommunityDetailSerializer
)
from civitas.serializer.reporter_data import ReporterDataSerializer
from civitas.permissions import CommunityAccessPermission
import json
from django.core.serializers import serialize

class CommunityAPI(APIView):
    """ Return community list """

    def get(self, request):
        """ Return data of features """
        return Response(
            CommunitySerializer(
                request.user.communities.order_by('name'), many=True
            ).data
        )

        
class CommunityDetailAPI(APIView):
    """ Return community list """
    permission_classes = (CommunityAccessPermission,)

    def get(self, request, pk):
        """ Return data of features """
        community = get_object_or_404(
            Community, pk=pk
        )
        detail = CommunityDetailSerializer(community).data
        organisation = community.organisation
        detail['organisation'] = OrganisationSerializer(
            organisation, user=request.user).data
        return Response(detail)


# SUMMARIES
class CommunityCOFAPI(APIView):
    """
    Return summary_cof of ReporterData
    """
    permission_classes = (CommunityAccessPermission,)

    def get(self, request, pk):
        """ Return data of features """
        community = get_object_or_404(
            Community, pk=pk
        )
        return Response(
            ReporterData.summary_cof(community)
        )


class CommunityPOFAPI(APIView):
    """
    Return summary_pof of ReporterData
    """
    permission_classes = (CommunityAccessPermission,)

    def get(self, request, pk):
        """ Return data of features """
        community = get_object_or_404(
            Community, pk=pk
        )
        return Response(
            ReporterData.summary_pof(community)
        )


class CommunityRiskAPI(APIView):
    """
    Return summary_risk of ReporterData
    """
    permission_classes = (CommunityAccessPermission,)

    def get(self, request, pk):
        """ Return data of features """
        community = get_object_or_404(
            Community, pk=pk
        )
        return Response(
            ReporterData.summary_risk(community)
        )


class ReporterDataDownloadAPI(APIView):
    """
    Download csv file for the reporter data
    """
    permission_classes = (CommunityAccessPermission,)

    def get(self, request, pk):
        """ Return data of features """
        community = get_object_or_404(
            Community, pk=pk
        )
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename="{community.name} Reporter Data.csv"'

        data = ReporterDataSerializer(ReporterData.by_community(community), many=True).data
        header = ReporterDataSerializer.Meta.fields

        writer = csv.DictWriter(response, fieldnames=header)
        writer.writeheader()
        for row in data:
            writer.writerow(row)

        return response
    
class AssetDataDownloadAPI(APIView):
    """
    Return summary_pof of ReporterData
    """
    permission_classes = (CommunityAccessPermission,)

    def get(self, request, pk):
        """ Return data of features """
        community = get_object_or_404(
            Community, pk=pk
        )
        
        return Response(
            ReporterData._showall(community)
        )
    
class AssetDataTable(APIView):
    """
    Return summary_pof of ReporterData
    """

    def __init__(self):
        self.features = None
        self.obj_paginator = None
        self.page_range = None
        self.community_id = None

    permission_classes = (CommunityAccessPermission,)
    

    def get(self, request, pk, page_num):
        """ Return data of features """
        self.community_id  = get_object_or_404(
            Community, pk=pk
        )
        #get data
        self.features = ReporterData._showall(self.community_id )
        per_page = 10
        self.obj_paginator = Paginator(self.features, per_page)
        page = self.obj_paginator.page(page_num).object_list
        self.page_range = self.obj_paginator.page_range

        context = {
            'page': list(page),
            'page_range': list(self.page_range)
        }

        return Response(context)

