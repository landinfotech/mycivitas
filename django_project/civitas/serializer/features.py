__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '18/11/20'

from rest_framework import serializers
from rest_framework_gis.serializers import (
    GeoFeatureModelSerializer, GeometrySerializerMethodField)

from civitas.models.feature.feature_geometry import (
    FeatureBase, FeatureGeometry
)
from civitas.models.view.reporter_data import ReporterData


class FeatureGeometryGeoSerializer(GeoFeatureModelSerializer):
    geometry = GeometrySerializerMethodField()
    sub_class = serializers.SerializerMethodField()
    system = serializers.SerializerMethodField()
    type = serializers.SerializerMethodField()
    cof = serializers.SerializerMethodField()
    pof = serializers.SerializerMethodField()
    condition = serializers.SerializerMethodField()
    quantity = serializers.SerializerMethodField()

    def get_geometry(self, obj):
        """ Get geometry
        :type obj: FeatureBase
        """
        try:
            return obj.featuregeometry.geometry()
        except FeatureGeometry.DoesNotExist:
            return None

    def get_sub_class(self, obj):
        """
        :type obj: FeatureBase
        """
        return obj.sub_class.name if obj.sub_class else '-'

    def get_system(self, obj):
        """
        :type obj: FeatureBase
        """
        return obj.system.name if obj.system else '-'

    def get_type(self, obj):
        """
        :type obj: FeatureBase
        """
        return obj.type.name if obj.type else '-'

    def get_cof(self, obj):
        """
        :type obj: FeatureBase
        """
        return obj.cof.name if obj.cof else '-'

    def get_pof(self, obj):
        """
        :type obj: FeatureBase
        """
        return obj.pof.name if obj.pof else '-'

    def get_condition(self, obj):
        """
        :type obj: FeatureBase
        """
        return obj.condition.name if obj.condition else '-'

    def get_quantity(self, obj):
        """
        :type obj: FeatureBase
        """
        return '{} {}'.format(obj.quantity, obj.sub_class.unit.name if obj.sub_class else '')

    def to_representation(self, instance):
        """ Additional properties
        :type instance: FeatureBase
        """
        data = super(FeatureGeometryGeoSerializer, self).to_representation(instance)
        data['properties']['class'] = instance.the_class.name if instance.the_class else '-'
        return data

    class Meta:
        model = FeatureBase
        geo_field = 'geometry'
        exclude = ('the_class', 'view_name')


class FeatureDataGeoSerializer(GeoFeatureModelSerializer):
    geometry = GeometrySerializerMethodField()
    identifier = serializers.SerializerMethodField()

    def get_geometry(self, obj):
        """ Get geometry
        :type obj: FeatureBase
        """
        try:
            return obj.featuregeometry.geometry()
        except FeatureGeometry.DoesNotExist:
            return None

    def get_identifier(self, obj: FeatureBase):
        """ identifier of object
        :type obj: ReporterData
        """
        return (
            f'{obj.the_class.description}.'
            f'{obj.sub_class.name}.{obj.id}'
        )

    def to_representation(self, obj: FeatureBase):
        """ Additional properties
        :type obj: FeatureBase
        """
        data = super(FeatureDataGeoSerializer, self).to_representation(obj)
        try:
            reporter_data = ReporterData.objects.get(feature_id=obj.id)
        except ReporterData.DoesNotExist:
            reporter_data = None

        system = obj.system
        community = system.community if system else None
        region = community.region if community else None
        province = region.province if region else None
        data['properties']['feature_id'] = obj.id
        data['properties']['Label'] = obj.display_label
        data['properties']['Province'] = province.name if province else None
        data['properties']['Region'] = region.name if region else None
        data['properties']['Community'] = community.name if community else None
        data['properties']['System'] = system.name if system else None
        data['properties']['Asset Class'] = obj.the_class.description if obj.the_class else None
        data['properties']['Asset Sub Class'] = obj.sub_class.name if obj.sub_class else None
        data['properties']['Condition'] = obj.condition.name if obj.condition else None
        data['properties']['Type'] = obj.type.name if obj.type else None

        data['properties']['Description'] = obj.description
        for feature_property in obj.featureproperty_set.all():
            data['properties'][feature_property.property.name.title()] = feature_property.value_text
        data['properties']['Install Date'] = obj.install_date
        data['properties']['Inspection Date'] = obj.inspection_date

        data['properties']['Lifespan'] = reporter_data.lifespan if reporter_data else None
        data['properties']['Age'] = reporter_data.age if reporter_data else None
        data['properties']['Remaining Years'] = reporter_data.remaining_years if reporter_data else None
        data['properties']['Risk Level'] = reporter_data.risk_level if reporter_data else None
        data['properties']['Probability of Failure'] = reporter_data.pof_name if reporter_data else None
        data['properties']['Consequence of Failure'] = reporter_data.cof_name if reporter_data else None
        data['properties']['Renewal Cost'] = reporter_data.renewal_cost if reporter_data else None
        data['properties']['Annual Reserve'] = reporter_data.annual_reserve if reporter_data else None
        data['properties']['Maintenance Cost'] = reporter_data.maintenance_cost if reporter_data else None
        return data

    class Meta:
        model = FeatureBase
        geo_field = 'geometry'
        id_field = 'identifier'
        fields = ('geometry', 'identifier', 'id')