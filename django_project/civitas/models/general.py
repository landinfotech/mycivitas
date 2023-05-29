__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '14/08/20'

from django.contrib.gis.db import models


class _Term(models.Model):
    """
    Abstract model for Every Term
    """
    name = models.CharField(max_length=512)
    description = models.TextField(null=True, blank=True)

    def __str__(self):
        return self.name

    class Meta:
        managed = False
        abstract = True


class Unit(_Term):
    """ Unit """

    class Meta:
        managed = False
        ordering = ('name',)
        db_table = 'unit'

    def __str__(self):
        return self.name
