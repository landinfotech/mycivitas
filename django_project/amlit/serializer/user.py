__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '11/11/20'

from rest_framework import serializers
from amlit.models import User


class UserSerializer(serializers.ModelSerializer):
    phone = serializers.SerializerMethodField()
    title = serializers.SerializerMethodField()

    def get_phone(self, obj):
        """
        :param obj:
        :type obj: User
        """
        if obj.phone:
            ext = '({}) '.format('.'.join(obj.phone.extensions)) if len(obj.phone.extensions) > 0 else ''
            return '{} {}'.format(ext, obj.phone.base_number_fmt)
        else:
            return '-'

    def get_title(self, obj):
        """
        :param obj:
        :type obj: User
        """
        return '-' if not obj.title else obj.title

    class Meta:
        model = User
        fields = '__all__'


class UserSearchSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username')
