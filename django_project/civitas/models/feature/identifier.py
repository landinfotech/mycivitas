__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '14/08/20'

from django.contrib.gis.db import models
from civitas.models.general import _Term, Unit


class Deterioration(_Term):
    """
    The process of becoming progressively worse.
    Contains name and the equation
    """
    equation = models.CharField(max_length=512)

    class Meta:
        managed = False
        ordering = ('name',)
        db_table = 'deterioration'

    def __str__(self):
        return self.name


class Condition(_Term):
    """
    Condition of feature
    1	very good
    2	good
    3	fair
    4	poor
    5	very poor
    """
    value = models.IntegerField()

    class Meta:
        managed = False
        ordering = ('name',)
        db_table = 'condition'

    def __str__(self):
        return self.name


class FeatureClass(_Term):
    """
    The first Level of the Asset Hierarchy as defined in "Background" Sheet
    ie. TRN = Transportation
    """

    class Meta:
        managed = False
        ordering = ('name',)
        db_table = 'asset_class'
        verbose_name_plural = "feature classes"

    def __str__(self):
        return self.name


class FeatureSubClass(_Term):
    """
    The second Level of the Asset Hierarchy as defined in "Background" Sheet
    ie. RD = Roads
    It is linked with AssetClass
    """
    unit = models.ForeignKey(
        Unit,
        blank=True, null=True,
        on_delete=models.SET_NULL,
        help_text='Default unit for this sub_class'
    )
    deterioration = models.ForeignKey(
        Deterioration,
        blank=True, null=True,
        on_delete=models.SET_NULL,
        help_text='Deterioration of this sub class'
    )

    class Meta:
        managed = False
        ordering = ('name',)
        db_table = 'asset_sub_class'
        verbose_name_plural = "feature sub classes"

    def __str__(self):
        return self.name


class FeatureType(_Term):
    """
    The third Level of the Asset Hierarchy as defined in "Background" Sheet
    """

    # This is information for the feature type
    lifespan = models.FloatField(
        blank=True, null=True,
        help_text='Total estimated life span of asset in years'
    )
    maintenance_cost = models.FloatField(
        blank=True, null=True,
        db_column='unit_maintenance_cost',
        help_text='Annual operation and maintenance cost (Default in canadian dollars)'
    )
    renewal_cost = models.FloatField(
        blank=True, null=True,
        db_column='unit_renewal_cost',
        help_text='Renewal cost (Default in canadian dollars)'
    )

    class Meta:
        managed = False
        ordering = ('name',)
        db_table = 'asset_type'

    def __str__(self):
        return self.name


class FeatureTypeCombination(_Term):
    """
    Combination between class, subclass and type
    """
    the_class = models.ForeignKey(
        FeatureClass,
        on_delete=models.CASCADE,
        db_column='class_id',
        verbose_name='class'
    )

    sub_class = models.ForeignKey(
        FeatureSubClass,
        on_delete=models.CASCADE
    )
    type = models.ForeignKey(
        FeatureType,
        on_delete=models.CASCADE
    )

    class Meta:
        managed = False
        ordering = ('the_class', 'sub_class', 'type')
        unique_together = ('the_class', 'sub_class', 'type')
        db_table = 'asset_classification_combination'

    def __str__(self):
        return '{}: {}: {}'.format(
            self.the_class, self.sub_class, self.type)
