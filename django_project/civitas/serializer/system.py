__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '11/11/20'

from rest_framework import serializers
from civitas.models.community import System


class SystemSerializer(serializers.ModelSerializer):
    class Meta:
        model = System
        fields = '__all__'
