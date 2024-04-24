from decimal import Decimal
from pprint import pprint
from django.contrib.gis.db import models
from django.db.models import Sum, Case, When, F, Func, Value, Q
from django.db.models.functions import Concat, Coalesce
from django.db.models.lookups import GreaterThan, LessThan, GreaterThanOrEqual, LessThanOrEqual
from civitas.models.community import Community
from .dashboard_data import DashboardData

class McExporter(models.Model):
    """
    Materialized View for mc exporter
    """

    feature_id = models.IntegerField(
        primary_key=True
    )
    province_name = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    province_code = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    regoin_code = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    community_id = models.IntegerField(
        null=True, blank=True)
    community_name = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    community_code= models.CharField(
        max_length=512,
        null=True, blank=True
    )
    system_id = models.IntegerField(
        null=True, blank=True
    )
    system_name = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    length = models.IntegerField(
        null=True, blank=True
    )
    area = models.IntegerField(
        null=True, blank=True
    )
    quantity = models.IntegerField(
        null=True, blank=True
    )
    renewal_cost_method = models.TextField(
        null=True, blank=True
    )
    maintenance_cost_method = models.TextField(
        null=True, blank=True
    )
    lifespan_method = models.TextField(
        null=True, blank=True
    )
    remaining_years_method = models.TextField(
        null=True, blank=True
    )
    maintenance_cost = models.FloatField(
        null=True, blank=True,
    )
    age = models.IntegerField(
        null=True, blank=True
    )
    remaining_years = models.IntegerField(
        null=True, blank=True
    )
    annual_reserve = models.FloatField(
        null=False, blank=False, default=0
    )
    pof_id = models.IntegerField(
        null=True, blank=True
    )
    pof_name = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    cof_id = models.IntegerField(
        null=True, blank=True
    )
    cof_name = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    risk_value = models.IntegerField(
        null=True, blank=True
    )
    risk_level = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    condition_id = models.IntegerField(
        null=True, blank=True
    )
    condition_name = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    class_name = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    class_description = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    sub_class_id = models.IntegerField(
        null=True, blank=True
    )
    sub_class_name = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    sub_class_description = models.TextField(
        null=True, blank=True
    )
    sub_class_deterioration_id = models.IntegerField(
        null=True, blank=True
    )
    sub_class_unit_id = models.IntegerField(
        null=True, blank=True
    )
    sub_class_unit_name = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    sub_class_unit_description = models.TextField(
        null=True, blank=True
    )
    type_id = models.IntegerField(
        null=True, blank=True
    )
    asset_type_name = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    asset_type_description = models.TextField(
        null=True, blank=True
    )
    feature_description = models.TextField(
        null=True, blank=True
    )
    view_name = models.TextField(
        null=True, blank=True
    )

    reported_length = models.TextField(
        null=True, blank=True
    )

    reported_area = models.TextField(
        null=True, blank=True
    )

    lookup_unit_maintenance_cost = models.TextField(
        null=True, blank=True
    )

    lookup_unit_renewal_cost = models.TextField(
        null=True, blank=True
    )

    input_maintenance_cost = models.TextField(
        null=True, blank=True
    )

    input_renewal_cost = models.TextField(
        null=True, blank=True
    )

    maintenance_cost_calc_method = models.TextField(
        null=True, blank=True
    )

    renewal_cost_calc_method = models.TextField(
        null=True, blank=True
    )

    reported_maintenance_cost = models.TextField(
        null=True, blank=True
    )

    reported_renewal_cost = models.TextField(
        null=True, blank=True
    )

    lookup_lifespan = models.TextField(
        null=True, blank=True
    )

    input_lifespan = models.TextField(
        null=True, blank=True
    )

    lifespan_calc_method = models.TextField(
        null=True, blank=True
    )

    reported_lifespan = models.TextField(
        null=True, blank=True
    )

    install_date = models.TextField(
        null=True, blank=True
    )

    inspection_date = models.TextField(
        null=True, blank=True
    )

    projected_sustainable_investment = models.TextField(
        null=True, blank=True
    )

    display_label = models.TextField(
        null=True, blank=True
    )

    brand = models.TextField(
        null=True, blank=True
    )

    model = models.TextField(
        null=True, blank=True
    )

    contractor = models.TextField(
        null=True, blank=True
    )

    material = models.TextField(
        null=True, blank=True
    )

    diameter = models.TextField(
        null=True, blank=True
    )

    width = models.TextField(
        null=True, blank=True
    )

    display_id = models.TextField(
        null=True, blank=True
    )

    power_output = models.TextField(
        null=True, blank=True
    )

    size =models.TextField(
        null=True, blank=True
    )

    load_rating = models.TextField(
        null=True, blank=True
    )

    depth = models.TextField(
        null=True, blank=True
    )

    footprint = models.TextField(
        null=True, blank=True
    )

    floor_area = models.TextField(
        null=True, blank=True
    )

    height = models.TextField(
        null=True, blank=True
    )

    structure_id = models.TextField(
        null=True, blank=True
    )

    service = models.TextField(
        null=True, blank=True
    )

    capacity = models.TextField(
        null=True, blank=True
    )

    stakeholder = models.TextField(
        null=True, blank=True
    )

    species = models.TextField(
        null=True, blank=True
    )

    gauge = models.TextField(
        null=True, blank=True
    )

    phase = models.TextField(
        null=True, blank=True
    )

    specification = models.TextField(
        null=True, blank=True
    )

    cores = models.TextField(
        null=True, blank=True
    )

    primary_voltage = models.TextField(
        null=True, blank=True
    )

    secondary_voltage = models.TextField(
        null=True, blank=True
    )

    voltage = models.TextField(
        null=True, blank=True
    )

    current = models.TextField(
        null=True, blank=True
    )

    communication = models.TextField(
        null=True, blank=True
    )

    account = models.TextField(
        null=True, blank=True
    )

    class Meta:
        managed = False
        db_table = 'mc_exporter'
        

    @staticmethod
    def _showall(community: Community) -> dict:
        """_summary_

        Args:
            community (Community): community object

        Returns:
            dict: detailed export per community per summary type
        """
        return McExporter.objects.filter(
            community_id=community.id
        ).values(
            'feature_id', 
            'class_name',
            'sub_class_name',
            'system_name',
            'age',  
            'area', 
            'asset_type_description', 
            'asset_type_name', 
            'class_name', 
            'cof_name', 
            'community_name', 
            'condition_name', 
            'length', 
            'maintenance_cost_method',
            'pof_name', 
            'quantity', 
            'remaining_years', 
            'remaining_years_method', 
            'renewal_cost_method', 
            'risk_level', 
            'risk_value', 
            'sub_class_name', 
            'sub_class_unit_description', 
            'sub_class_unit_name', 
            'system_name', 
            'annual_reserve',
            'maintenance_cost',
        ).order_by('system_name')
    
    @staticmethod
    def _showdefault(community: Community) -> dict:
        """_summary_

        Args:
            community (Community): community object

        Returns:
            dict: detailed export per community per summary type
        """
        return McExporter.objects.filter(
            community_id=community.id
        ).values(
            "feature_id",
            "community_name",
            "system_name",
            "sub_class_name",
            "asset_type_name",
            "feature_description",
            "quantity",
            "sub_class_unit_description",
            "reported_renewal_cost",
            "reported_lifespan",
        ).order_by('system_name')
    
    @staticmethod
    def _showdetailed(community: Community) -> dict:
        """_summary_

        Args:
            community (Community): community object

        Returns:
            dict: detailed export per community per summary type
        """
        return McExporter.objects.filter(
            community_id=community.id
        ).values(
            "feature_id",
            "community_name",
            "system_name",
            "sub_class_name",
            "asset_type_name",
            "feature_description",
            "quantity",
            "sub_class_unit_description",
            "reported_renewal_cost",
            "condition_id",
            "condition_name",
            "inspection_date",
            "install_date",
            "age",
            "remaining_years",
            "pof_id",
            "pof_name",
            "cof_id",
            "cof_name",
            "risk_value",
            "risk_level",
            "area",
            "reported_length",
            "diameter",
            "material",
            "display_label"
        ).order_by('system_name')
    
    @staticmethod
    def _showcustom(community: Community, selected_value) -> dict:
        """_summary_

        Args:
            community (Community): community object

        Returns:
            dict: detailed export per community per summary type
        """

        return McExporter.objects.filter(
            community_id=community.id
        ).values(
            selected_value
        ).order_by('system_name')

    
