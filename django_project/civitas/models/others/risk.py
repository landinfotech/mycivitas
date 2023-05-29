__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '05/11/20'

from django.contrib.gis.db import models


class COF(models.Model):
    """
    Consequence of Failure
    """
    name = models.TextField(
        null=True, blank=True
    )

    def __str__(self):
        return self.name

    class Meta:
        managed = False
        db_table = 'cof'


class POF(models.Model):
    """
    Probability of Failure
    """
    name = models.TextField(
        null=True, blank=True
    )

    def __str__(self):
        return self.name

    class Meta:
        managed = False
        db_table = 'pof'


class Risk(models.Model):
    """
    Probability of Failure
    """
    pof = models.ForeignKey(
        POF,
        null=True, blank=True,
        on_delete=models.SET_NULL,
        db_column='pof_value'
    )
    cof = models.ForeignKey(
        COF,
        null=True, blank=True,
        on_delete=models.SET_NULL,
        db_column='cof_value'
    )
    value = models.IntegerField(
        null=True, blank=True,
        db_column='risk_value')

    level = models.CharField(
        max_length=512,
        null=True, blank=True,
        db_column='risk_level')

    class Meta:
        managed = False
        db_table = 'risk_lookup'
