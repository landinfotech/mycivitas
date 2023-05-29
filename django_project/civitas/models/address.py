__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '05/11/20'

from django.contrib.gis.db import models


class CivicAddress(models.Model):
    """
    Civic Address object
    """
    geom = models.PointField(
        null=True, blank=True
    )
    pntid = models.BigIntegerField(
        null=True, blank=True
    )
    segid = models.BigIntegerField(
        null=True, blank=True
    )
    civicnum = models.BigIntegerField(
        null=True, blank=True
    )
    civsuffix = models.CharField(
        max_length=512,
        null=True, blank=True)
    unit_num = models.CharField(
        max_length=512,
        null=True, blank=True)
    add_loc = models.CharField(
        max_length=512,
        null=True, blank=True)
    strprefix = models.CharField(
        max_length=512,
        null=True, blank=True)
    strname = models.CharField(
        max_length=512,
        null=True, blank=True)
    strsuffix = models.CharField(
        max_length=512,
        null=True, blank=True)
    strdir = models.CharField(
        max_length=512,
        null=True, blank=True)
    comm_id = models.BigIntegerField(
        null=True, blank=True
    )
    comm = models.CharField(
        max_length=512,
        null=True, blank=True)
    mun = models.CharField(
        max_length=512,
        null=True, blank=True)
    county = models.CharField(
        max_length=512,
        null=True, blank=True)

    class Meta:
        managed = False
        db_table = 'civic_address'
        verbose_name_plural = "civic addresses"
