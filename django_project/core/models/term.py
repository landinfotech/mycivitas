__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '18/03/21'

from django.contrib.gis.db import models
from django.utils.translation import ugettext_lazy as _


class TermModel(models.Model):
    """ Abstract model for Term """

    name = models.CharField(
        _('name'), max_length=512, unique=True)
    description = models.TextField(
        _('description'), null=True, blank=True)

    def __str__(self):
        return self.name

    class Meta:
        abstract = True
        ordering = ('name',)
