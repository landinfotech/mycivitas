__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '11/11/20'

from rest_framework import serializers
from civitas.models.community import Community
from civitas.serializer.system import (
    SystemSerializer
)


class CommunitySerializer(serializers.ModelSerializer):
    region = serializers.SerializerMethodField()
    province = serializers.SerializerMethodField()

    def get_region(self, obj):
        """ Return region of community
        :param obj:
        :type obj: Community
        """
        return obj.region.name

    def get_province(self, obj):
        """ Return province of community
        :param obj:
        :type obj: Community
        """
        return obj.region.province.name

    class Meta:
        model = Community
        exclude = ['geometry', 'description']


class CommunityDetailSerializer(CommunitySerializer):
    systems = serializers.SerializerMethodField()

    def get_systems(self, obj):
        """ Return system of community
        :param obj:
        :type obj: Community
        """
        return SystemSerializer(obj.system_set.order_by('name'), many=True).data

    class Meta:
        model = Community
        fields = '__all__'
