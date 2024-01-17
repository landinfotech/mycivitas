__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '11/11/20'

from django.conf import settings
from django.db import connections
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
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator

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
    
class AssetDataDefaultAPI(APIView):
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
            ReporterData._showdefault(community)
        )
    
class AssetDataDetailedAPI(APIView):
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
            ReporterData._showdetailed(community)
        )
    
class AssetDataCustomAPI(APIView):
    """
    Return summary_pof of ReporterData
    """

    @method_decorator(csrf_exempt)
    def post(self, request):
        """ Return data of features """
        pk = request.POST["pk"]
        selected  = request.POST.getlist("selected[]")
        
        community = get_object_or_404(
            Community, pk=pk
        )

        final_list = []
        for item in selected:
            final_list.append(ReporterData._showcustom(community, item))

        print(final_list)
        
        return Response(
            final_list
        )
    
    """
    Return summary_pof of ReporterData
    """
    permission_classes = (CommunityAccessPermission,)

    def get(self, request, pk):
        """ Return data of features """
        community = get_object_or_404(
            Community, pk=pk
        )

        data = []

        sql = f"SELECT DISTINCT system_name, asset_identifier FROM mv_features WHERE community_id = {pk};"
        with connections[settings.CIVITAS_DATABASE].cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()
            for row in rows:
                system_name = row[0]
                asset_identifier = row[1]
                if not any(d['system_name'] == system_name for d in data):
                    data.append({"system_name": system_name, "asset_identifier": [asset_identifier]})
                else:
                    index = [i for i,_ in enumerate(data) if _['system_name'] == system_name][0]
                    data[index]["asset_identifier"].append(asset_identifier)
        
        return Response(
            data
        )
    
class AssetClassAPI(APIView):
    """
    Return summary_pof of ReporterData
    """
    permission_classes = (CommunityAccessPermission,)

    def get(self, request, pk):
        """ Return data of features """
        community = get_object_or_404(
            Community, pk=pk
        )

        data = []

        sql = f"""SELECT DISTINCT 
                mv_features.asset_sub_class, 
                mv_features.asset_identifier,
                mv_features.def_stylename,
                mv_features.type,
                asset_class.description 
                FROM asset_class 
                LEFT JOIN mv_features ON mv_features.asset_identifier = asset_class.name 
                WHERE mv_features.community_id = {pk};"""
        with connections[settings.CIVITAS_DATABASE].cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()
            for row in rows:
                
                asset_sub_class = row[0]
                asset_identifier = row[1]
                def_stylename = row[2]
                asset_type = row[3]
                asset_class = row[4]

                if not any(d['asset_class'] == asset_class for d in data):
                    data.append({
                        "asset_class": asset_class, 
                        "asset_identifier": asset_identifier, 
                        "asset_sub_class": [{'asset': asset_sub_class, 'type': [asset_type]}], 
                        "def_stylename": [def_stylename]
                    })
                else:
                    index = [i for i,_ in enumerate(data) if _['asset_class'] == asset_class][0]    
                    if not any(d['asset'] == asset_sub_class for d in data[index]["asset_sub_class"]):
                        data[index]["asset_sub_class"].append({'asset': asset_sub_class, 'type': [asset_type]})
                    else:
                        _index = [i for i,_ in enumerate(data[index]["asset_sub_class"]) if _['asset'] == asset_sub_class][0]  
                        data[index]["asset_sub_class"][_index]["type"].append(asset_type)
        
        return Response(
            data
        )
    
class AssetSubClassAPI(APIView):
    """
    Return summary_pof of ReporterData
    """
    permission_classes = (CommunityAccessPermission,)

    def get(self, request, pk):
        """ Return data of features """
        community = get_object_or_404(
            Community, pk=pk
        )

        data = []

        sql = f"SELECT DISTINCT asset_sub_class, asset_identifier FROM mv_features WHERE community_id = {pk};"
        with connections[settings.CIVITAS_DATABASE].cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()
            for row in rows:
                asset_sub_class = row[0]
                asset_identifier = row[1]
                if not any(d['asset_sub_class'] == asset_sub_class for d in data):
                    data.append({"asset_sub_class": asset_sub_class, "asset_identifier": [asset_identifier]})
                else:
                    index = [i for i,_ in enumerate(data) if _['asset_sub_class'] == asset_sub_class][0]
                    data[index]["asset_identifier"].append(asset_identifier)
        
        return Response(
            data
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
    
class SystemNameAPI(APIView):
    """
    Return summary_pof of ReporterData
    """
    permission_classes = (CommunityAccessPermission,)

    def get(self, request, pk):
        """ Return data of features """
        community = get_object_or_404(
            Community, pk=pk
        )

        data = []

        sql = f"SELECT DISTINCT system_name, asset_identifier FROM mv_features WHERE community_id = {pk};"
        with connections[settings.CIVITAS_DATABASE].cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()
            for row in rows:
                system_name = row[0]
                asset_identifier = row[1]
                if not any(d['system_name'] == system_name for d in data):
                    data.append({"system_name": system_name, "asset_identifier": [asset_identifier]})
                else:
                    index = [i for i,_ in enumerate(data) if _['system_name'] == system_name][0]
                    data[index]["asset_identifier"].append(asset_identifier)
        
        return Response(
            data
        )

