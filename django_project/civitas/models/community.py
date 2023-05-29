__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '14/08/20'

from django.contrib.gis.db import models
from civitas.models.general import _Term


class _Administrative(models.Model):
    """
    Administrative object
    """
    code = models.CharField(
        unique=True,
        max_length=128,
        help_text='Administrative code'
    )
    name = models.CharField(max_length=512)
    description = models.TextField(null=True, blank=True)
    geometry = models.MultiPolygonField(
        null=True, blank=True
    )

    class Meta:
        managed = False
        abstract = True

    def __str__(self):
        return '{}'.format(self.name)


class Province(_Administrative):
    """
    Administrative province
    """

    class Meta:
        managed = False
        db_table = 'province'


class Region(_Administrative):
    """
    Administrative region
    """

    province = models.ForeignKey(
        Province, on_delete=models.CASCADE)

    class Meta:
        managed = False
        db_table = 'region'


class Community(_Administrative):
    """
    Administrative community
    """

    region = models.ForeignKey(
        Region, on_delete=models.CASCADE)
    currency = models.CharField(
        max_length=512)

    class Meta:
        managed = False
        db_table = 'community'
        verbose_name_plural = "communities"

    def __str__(self):
        return '{} ({})'.format(self.name, self.code)

    @property
    def organisation(self):
        from amlit.models.organisation import Organisation
        try:
            return Organisation.objects.get(community_code=self.code)
        except Organisation.DoesNotExist:
            return None


class System(_Term):
    """
     System is a collection of all of feature
    """
    community = models.ForeignKey(
        Community, blank=True, null=True,
        on_delete=models.SET_NULL
    )

    class Meta:
        managed = False
        db_table = 'system'
