__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '18/11/20'

from django.shortcuts import get_object_or_404
from rest_framework.response import Response
from rest_framework.views import APIView

from civitas.models.feature.feature_geometry import FeatureBase
from civitas.serializer.features import (
    FeatureGeometryGeoSerializer,
    FeatureDataGeoSerializer
)


class FeatureGeojsonDetailAPI(APIView):
    """
    get:
    Return geojson of a feature
    """

    def get(self, request, pk):
        """ Return data of features """
        feature = get_object_or_404(FeatureBase, pk=pk)
        return Response(
            FeatureGeometryGeoSerializer(feature).data
        )


class ReporterDataGeojsonDetailAPI(APIView):
    """
    get:
    Return geojson of a feature
    """

    def get(self, request, pk):
        """ Return data of features """
        feature = get_object_or_404(FeatureBase, pk=pk)
        return Response(
            FeatureDataGeoSerializer(feature).data
        )
