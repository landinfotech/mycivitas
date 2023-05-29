__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '14/08/20'

from datetime import datetime
from django.contrib.gis.db import models
from civitas.models.feature.identifier import (
    Condition, FeatureClass, FeatureSubClass, FeatureType
)
from civitas.models.community import System
from civitas.models.others import AimsoirFeatureCode, COF, POF


class FeatureBase(models.Model):
    """
    Model for base feature.
    Every feature needs to override this model
    """

    install_date = models.DateField(
        help_text='When this feature is installed'
    )
    inspection_date = models.DateField(
        help_text='When this feature is inspected'
    )
    quantity = models.FloatField(
        help_text='Quantity of the feature. '
                  'The unit is based on the sub class')
    description = models.TextField(
        null=True, blank=True
    )
    display_label = models.TextField(
        null=True, blank=True
    )
    the_class = models.ForeignKey(
        FeatureClass,
        null=True, blank=True,
        on_delete=models.SET_NULL,
        db_column='class_id',
        verbose_name='class'
    )
    sub_class = models.ForeignKey(
        FeatureSubClass,
        null=True, blank=True,
        on_delete=models.SET_NULL
    )
    type = models.ForeignKey(
        FeatureType,
        null=True, blank=True,
        on_delete=models.SET_NULL
    )
    system = models.ForeignKey(
        System,
        null=True, blank=True,
        on_delete=models.SET_NULL,
        help_text='What system the feature belongs to'
    )
    pof = models.ForeignKey(
        POF,
        null=True, blank=True,
        on_delete=models.SET_NULL,
        db_column='pof',
        verbose_name='pof'
    )
    cof = models.ForeignKey(
        COF,
        null=True, blank=True,
        on_delete=models.SET_NULL,
        db_column='cof',
        verbose_name='cof'
    )
    aimsoir_feature_code = models.ForeignKey(
        AimsoirFeatureCode,
        null=True, blank=True,
        on_delete=models.SET_NULL,
        db_column='aimsoir_feature_code'
    )
    capital_project_id = models.SmallIntegerField(
        null=True, blank=True
    )

    # calculated field
    condition = models.ForeignKey(
        Condition,
        null=True, blank=True,
        on_delete=models.SET_NULL,
        help_text='Condition of the feature'
    )

    renewal_cost = models.FloatField(
        null=True, blank=True,
        help_text='How much cost for renewal the feature with all quantity'
    )
    maintenance_cost = models.FloatField(
        null=True, blank=True,
        help_text='How much cost to maintenance the feature with all quantity'
    )

    # others
    file_reference = models.TextField(
        null=True, blank=True
    )
    view_name = models.TextField(
        null=True, blank=True
    )

    class Meta:
        managed = False
        db_table = 'feature_base'

    def save(self, *args, **kwargs):
        super(FeatureBase, self).save(*args, **kwargs)

    def lifespan(self):
        """ Return lifespan of feature"""
        if not self.type:
            return None
        return self.type.lifespan

    def calculation(self):
        """ Calculate all field that needs calculation"""
        if self.featurecalculation_set.all().count():
            return self.featurecalculation_set.all()[0]
        return None
