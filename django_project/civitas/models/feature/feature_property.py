__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '09/09/20'

from django.contrib.gis.db import models
from civitas.models.feature.feature_base import FeatureBase


class Property(models.Model):
    """
    This is property for feature
    """
    name = models.TextField(
        null=True, blank=True
    )

    def __str__(self):
        return self.name

    class Meta:
        managed = False
        db_table = 'property'


class FeatureProperty(models.Model):
    """
    This is additional property for the feature
    """
    feature = models.ForeignKey(
        FeatureBase,
        on_delete=models.CASCADE
    )
    property = models.ForeignKey(
        Property,
        on_delete=models.CASCADE
    )
    value_text = models.TextField(
        null=True, blank=True
    )

    class Meta:
        managed = False
        db_table = 'feature_property'
