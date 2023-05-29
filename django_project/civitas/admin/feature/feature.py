__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '09/09/20'

from django.contrib import admin
from django.contrib.gis.admin import OSMGeoAdmin
from civitas.models.feature.feature_base import FeatureBase
from civitas.models.feature.feature_geometry import FeatureGeometry
from civitas.models.feature.feature_property import FeatureProperty


class FeaturePropertyInline(admin.TabularInline):
    model = FeatureProperty
    extra = 0


class FeatureGeometryInline(admin.TabularInline):
    model = FeatureGeometry
    extra = 0


class FeatureBaseAdmin(admin.ModelAdmin):
    list_display = (
        'type', 'system', 'install_date')
    readonly_fields = (
        'estimated_renewal_cost', 'estimated_maintenance_cost', 'age',
        'remaining_life', 'remaining_life_percent', 'annual_reserve_cost'
    )
    list_filter = ('the_class', 'sub_class', 'type')
    inlines = [FeaturePropertyInline, FeatureGeometryInline]

    # TODO: LIT
    #  after these fields already uncommented, remove these
    # CALCULATION
    def estimated_renewal_cost(self, obj):
        """ return renewal cost based on calculation"""
        if obj.calculation():
            return obj.calculation().renewal_cost()
        return '-'

    def estimated_maintenance_cost(self, obj):
        """ return maintenance cost based on calculation"""
        if obj.calculation():
            return obj.calculation().maintenance_cost()
        return '-'

    def age(self, obj):
        """ return age based on calculation"""
        if obj.calculation():
            return obj.calculation().age
        return '-'

    def remaining_life(self, obj):
        """ return remaining life based on calculation"""
        if obj.calculation():
            return obj.calculation().remaining_life()
        return '-'

    def remaining_life_percent(self, obj):
        """ return remaining life percent based on calculation"""
        if obj.calculation():
            return obj.calculation().remaining_life_percent()
        return '-'

    def annual_reserve_cost(self, obj):
        """ return annual reserve cost based on calculation"""
        if obj.calculation():
            return obj.calculation().annual_reserve_cost()
        return '-'


class FeatureGeometryAdmin(OSMGeoAdmin):
    default_lon = -13271942
    default_lat = 6485105
    default_zoom = 12


admin.site.register(FeatureBase, FeatureBaseAdmin)
admin.site.register(FeatureGeometry, FeatureGeometryAdmin)
