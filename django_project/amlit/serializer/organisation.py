__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '11/11/20'

from rest_framework import serializers
from amlit.models import Organisation, UserRole


class OrganisationSerializer(serializers.ModelSerializer):
    def __init__(self, *args, **kwargs):
        self.user = kwargs.pop('user')
        super().__init__(*args, **kwargs)

    class Meta:
        model = Organisation
        fields = '__all__'

    def to_representation(self, instance: Organisation):
        data = super(OrganisationSerializer, self).to_representation(instance)
        data.update({
            'permissions': {
                'create_ticket': instance.has_permission().create_ticket(self.user)
            },
            'operators': [
                (user.id, user.__str__()) for user in instance.operators
            ]
        })
        return data
