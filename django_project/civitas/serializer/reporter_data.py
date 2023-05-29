__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '24/08/21'

from rest_framework import serializers
from civitas.models.view.reporter_data import ReporterData


class ReporterDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReporterData
        fields = [
            'feature_id', 'province_id', 'province_name', 'region_id', 'region_name',
            'community_id', 'community_name', 'system_id', 'system_name',
            'length', 'area', 'quantity', 'renewal_cost_method', 'maintenance_cost_method',
            'lifespan_method', 'remaining_years_method', 'deterioration_name',
            'renewal_cost', 'maintenance_cost', 'lifespan', 'age', 'remaining_years',
            'annual_reserve', 'pof_id', 'pof_name', 'cof_id', 'cof_name',
            'risk_value', 'risk_level', 'condition_id', 'condition_name', 'class_id',
            'class_name', 'sub_class_id', 'sub_class_name', 'sub_class_description',
            'sub_class_deterioration_id', 'sub_class_unit_id', 'sub_class_unit_name',
            'sub_class_unit_description', 'type_id', 'asset_type_name', 'asset_type_description'
        ]
