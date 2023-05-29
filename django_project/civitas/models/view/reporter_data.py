__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '14/07/21'

from django.contrib.gis.db import models
from django.db.models import Sum, Case, When, F
from django.db.models.functions import Concat
from django.db.models.lookups import GreaterThan, LessThan, GreaterThanOrEqual, LessThanOrEqual
from civitas.models.community import Community
from .dashboard_data import DashboardData

class ReporterData(models.Model):
    """
    Materialized View for reported data
    """

    FIELDS = (
        'feature_id', 'class_name', 'sub_class_name', 'community_name',
        'cof_id', 'pof_id', 'risk_value',
        'renewal_cost', 'maintenance_cost'
    )
    feature_id = models.IntegerField(
        primary_key=True
    )
    province_id = models.IntegerField(
        null=True, blank=True
    )
    province_name = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    region_id = models.IntegerField(
        null=True, blank=True
    )
    region_name = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    community_id = models.IntegerField(
        null=True, blank=True)
    community_name = models.CharField(
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
    deterioration_name = models.CharField(
        max_length=512,
        null=True, blank=True
    )
    renewal_cost = models.FloatField(
        null=True, blank=True,
    )
    maintenance_cost = models.FloatField(
        null=True, blank=True,
    )
    lifespan = models.IntegerField(
        null=True, blank=True
    )
    age = models.IntegerField(
        null=True, blank=True
    )
    remaining_years = models.IntegerField(
        null=True, blank=True
    )
    annual_reserve = models.IntegerField(
        null=True, blank=True
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
    class_id = models.IntegerField(
        null=True, blank=True
    )
    class_name = models.CharField(
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

    class Meta:
        managed = False
        db_table = 'reporter_data'
        

    @staticmethod
    def _summary(community: Community, summary_type: str) -> dict:
        """_summary_

        Args:
            community (Community): community object
            summary_type (str): pof_name | cof_name

        Returns:
            dict: detailed export per community per summary type
        """
        return ReporterData.objects.filter(
            community_id=community.id
        ).order_by('system_name').extra(
            select={'summary_type': summary_type}
        ).values(
            'class_name',
            'sub_class_id',
            'sub_class_name',
            'summary_type',
            'system_name',
            
        ).annotate(
            maintenance_cost=Sum('maintenance_cost'),
            renewal_cost=Sum('renewal_cost')
        ).order_by('system_name')
    
    @staticmethod
    def _showall(community: Community) -> dict:
        """_summary_

        Args:
            community (Community): community object

        Returns:
            dict: detailed export per community per summary type
        """
        return ReporterData.objects.filter(
            community_id=community.id
        ).values(
            'feature_id', 
            'class_name',
            'sub_class_name',
            'system_name',
            'age', 
            'annual_reserve', 
            'area', 
            'asset_type_description', 
            'asset_type_name', 
            'class_name', 
            'cof_name', 
            'community_name', 
            'condition_name', 
            'deterioration_name', 
            'length', 
            'lifespan', 
            'lifespan_method', 
            'maintenance_cost',
            'maintenance_cost_method',
            'pof_name', 
            'quantity', 
            'remaining_years', 
            'remaining_years_method', 
            'renewal_cost', 
            'renewal_cost_method', 
            'risk_level', 
            'risk_value', 
            'sub_class_name', 
            'sub_class_unit_description', 
            'sub_class_unit_name', 
            'system_name', 
        ).order_by('system_name')

    @staticmethod
    def dashboard(community: Community) -> dict:
        """_dashboard_

        Args:
            community (Community): community object

        Returns:
            array: dictionary of each cost breakdown
        """
        data = ReporterData.objects.filter(
            community_id=community.id
            ).exclude(
                system_name__in=[
                    'Non-Municipal Infrastructure',
                    'Abandoned Infrastructure'
                    ]
            ) 
        system_names = data.exclude(system_name=None) \
            .order_by('system_name') \
            .values('system_name') \
            .distinct() \
            .annotate(label=Concat('system_name', models.Value('')))
        renewal_cost_of_assets = data.exclude(system_name=None) \
            .order_by('system_name') \
            .values('system_name') \
            .annotate(label=Concat('system_name', models.Value('')), values=Sum('renewal_cost'))       
        maintenance_cost_of_assets = data.exclude(system_name=None) \
            .order_by('system_name') \
            .values('system_name') \
            .distinct() \
            .annotate(label=Concat('system_name', models.Value('')), values=Sum('maintenance_cost'))      
        risk_renewal_of_assets = data.exclude(system_name=None) \
            .order_by('system_name') \
            .values('system_name', 'risk_level') \
            .distinct() \
            .annotate(label=Concat('system_name', models.Value('')), values=Sum('renewal_cost'))     
        remaining_years_renewal_cost = data.exclude(system_name=None) \
            .order_by('system_name') \
            .values('system_name') \
            .distinct() \
            .annotate(label=Concat('system_name', models.Value('')), values=Sum('renewal_cost'))    
        remaining_years_renewal_risk_cost = data.exclude(system_name=None) \
            .order_by('system_name') \
            .values('system_name', 'risk_level') \
            .distinct() \
            .annotate(label=Concat('system_name', models.Value('')), values=Sum('renewal_cost'))  
        annual_reserve = data.exclude(system_name=None) \
            .order_by('system_name') \
            .values('system_name') \
            .distinct() \
            .annotate(label=Concat('system_name', models.Value('')), values=Sum('annual_reserve'))       

        _dashboard = DashboardData(data=data)  

        qs = [
            {
                'id': 'renewal_cost', 
                "title": "Renewal costs of assets",
                "qs": renewal_cost_of_assets, 
                'type': 'non_stacked', 
                'sum': renewal_cost_of_assets.aggregate(sum=Sum('values')),
                'description': 'Replacement costs are based on current available costs and include the following components: Capital Costs - 65%, Contingency - 15%, Design - 10%, Inspections and Removal - 10%. As a starting point, a default replacement cost is applied for each asset type.  However, in some cases, where the above general formula is not applicable, or requires significantly less or more effort in one of the above areas, a custom cost might have been applied. This value will override the default value.'
            },              
            {
                'id': 'maintenenance_cost', 
                "title": "Maintenance costs of assets",
                "qs": maintenance_cost_of_assets, 
                'type': 'non_stacked',
                'sum': maintenance_cost_of_assets.aggregate(sum=Sum('values')),
                'description': 'Maintenance costs are the estimated annual cost to maintain assets. As a starting point, a default value of 10% of the renewal cost is used'
            },   
            {
                'id': 'annual_reserve', 
                "title": "Annual Average Infrastructure Demand",
                "qs": annual_reserve, 
                'type': 'non_stacked',
                'sum': annual_reserve.aggregate(sum=Sum('values')),
                'description':  "This graph uses lifespan projections and renewal costs for a long-term outlook of  infrastructure. This projection is theoretical and is not a realistic indication of spending timelines. A valuable output of this projection is an annualized infrastructure demand, indicated as a dotted line on the graph. This annualized value is obtained by dividing the renewal cost by the lifespan for each asset in the database and then summing the total. As lifespan and renewal cost data are updated, the annual infrastructure demand will update. The annual infrastructure demand could be lowered by committing to operations and maintenance programs to extend lifespans, deciding to rehabilitate versus replace, and more. The values shown in the graph is based on current $ values and the actual value of this average annual investment will increase over time with inflation."
            },   
            {
                'id': 'system_risk_renewal', 
                "title": "Risk By System",
                "qs": risk_renewal_of_assets, 
                "formatted": _dashboard.stacked_a(risk_renewal_of_assets),
                "total_bottom": _dashboard.stacked_a_total(_dashboard.stacked_a(risk_renewal_of_assets)),
                'type': 'stacked_a',
                'sum': risk_renewal_of_assets.aggregate(sum=Sum('values')),
                'description': 'A risk value is obtained by combining Probability of Failure  (PoF) and Consequence of Failure (CoF) values as per the following matrix. It is common asset management practice to shift the matrix in favour of the consequence of failure,'
            },        
            {
                'id': 'remaining_years_renewal_system', 
                "title": "Remaining Years by Renewal Cost by System",
                "qs": remaining_years_renewal_cost, 
                "formatted": _dashboard.stacked_b_list(system_names),
                "total": _dashboard.stacked_b_total(_dashboard.stacked_b_list(system_names), system_names=system_names),
                "graph": _dashboard.stacked_b_graph(_dashboard.stacked_b_list(system_names), system_names=system_names),
                "pdf_table_1": _dashboard.pdf_table_1(_dashboard.stacked_b_list(system_names)),
                "pdf_table_2": _dashboard.pdf_table_2(_dashboard.stacked_b_list(system_names)),
                'type': 'stacked_b',
                'system_names': system_names,
                'sum': remaining_years_renewal_cost.aggregate(sum=Sum('values')),
                'description': ''
            },   
            {
                'id': 'remaining_years_renewal_risk', 
                "title": "Remaining Years by Renewal Cost by Risk",
                "qs": remaining_years_renewal_risk_cost, 
                "formatted":  _dashboard.stacked_c_list(),
                "graph":  _dashboard.stacked_c_graph( _dashboard.stacked_c_list()),
                "total": _dashboard.stacked_c_total( _dashboard.stacked_c_list()),
                "pdf_table_1": _dashboard.pdf_table_1(_dashboard.stacked_c_list()),
                "pdf_table_2": _dashboard.pdf_table_2(_dashboard.stacked_c_list()),
                'type': 'stacked_c',
                'risk_levels': _dashboard.risk_level_list,
                'sum': remaining_years_renewal_risk_cost.aggregate(sum=Sum('values')),
                'description': ''
            },  
        ]
        return qs

    @staticmethod
    def summary_cof(community: Community) -> dict:
        """
        Return summary of cof for specific community
        The return will be grouped by class
        """
        return ReporterData._summary(community, 'cof_name')

    @staticmethod
    def summary_pof(community: Community) -> dict:
        """
        Return summary of pof for specific community
        The return will be grouped by class
        """
        return ReporterData._summary(community, 'pof_name')

    @staticmethod
    def summary_risk(community: Community) -> dict:
        """
        Return summary of risk for specific community
        The return will be grouped by class
        """
        return ReporterData._summary(community, 'risk_level')
    
    @staticmethod
    def by_community_all(community: Community) -> dict:
        """
        Return reporter_data by community
        """
        return ReporterData._showall(community)

    @staticmethod
    def by_community(community: Community) -> dict:
        """
        Return reporter_data by community
        """
        return ReporterData.objects.filter(
            community_id=community.id
        )[0:2]
    
