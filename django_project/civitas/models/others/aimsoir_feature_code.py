__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '05/11/20'
from django.contrib.gis.db import models


class AimsoirFeatureCode(models.Model):
    """
    AimsoirFeatureCode
    """
    code = models.TextField(
        null=True, blank=True
    )
    description = models.TextField(
        null=True, blank=True
    )

    def __str__(self):
        return self.code

    class Meta:
        managed = False
        db_table = 'aimsoir_feature_codes'
