__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '05/11/20'

from django.contrib.gis.db import models
from civitas.models.community import Community
from civitas.models.feature import FeatureBase


class CapitalProject(models.Model):
    """
    Capital project object
    """
    name = models.CharField(max_length=512, null=True, blank=True)
    year = models.IntegerField(null=True, blank=True)
    proforma_cost = models.FloatField(null=True, blank=True)

    community = models.ForeignKey(
        Community,
        null=True, blank=True,
        on_delete=models.SET_NULL
    )
    geometry = models.PolygonField(
        null=True, blank=True
    )

    class Meta:
        managed = False
        db_table = 'capital_projects'

    def __str__(self):
        return '{}'.format(self.name)


class CapitalProjectFeatureCombination(models.Model):
    """
    Capital project feature combinationobject
    """

    capital_project = models.ForeignKey(
        CapitalProject,
        null=True, blank=True,
        on_delete=models.SET_NULL
    )
    feature = models.ForeignKey(
        FeatureBase,
        null=True, blank=True,
        on_delete=models.SET_NULL
    )

    class Meta:
        managed = False
        db_table = 'capital_project_feature_combination'
