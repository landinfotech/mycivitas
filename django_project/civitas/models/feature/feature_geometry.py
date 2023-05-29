__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '14/08/20'

from django.contrib.gis.db import models
from civitas.models.feature.feature_base import FeatureBase


class FeatureGeometry(models.Model):
    """
    Geometry of feature base
    """

    feature = models.OneToOneField(
        FeatureBase,
        on_delete=models.CASCADE
    )
    geom_point = models.PointField(
        null=True, blank=True
    )
    geom_line = models.LineStringField(
        null=True, blank=True
    )
    geom_polygon = models.PolygonField(
        null=True, blank=True
    )

    class Meta:
        managed = False
        db_table = 'feature_geometry'
        verbose_name_plural = "feature geometries"

    def geometry(self):
        """ return geometry of feature """
        if self.geom_point:
            return self.geom_point
        if self.geom_line:
            return self.geom_line
        if self.geom_polygon:
            return self.geom_polygon
