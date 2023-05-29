__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '14/08/20'

from django.contrib import admin
from civitas.models.feature.identifier import (
    Condition, Deterioration, FeatureClass,
    FeatureSubClass, FeatureType, FeatureTypeCombination
)


class DeteriorationAdmin(admin.ModelAdmin):
    list_display = ('name', 'equation')


class FeatureClassAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')


class FeatureSubClassAdmin(admin.ModelAdmin):
    list_display = ('name', 'description', 'unit', 'deterioration')


class FeatureTypeAdmin(admin.ModelAdmin):
    list_display = (
        'name', 'description', 'maintenance_cost', 'renewal_cost', 'lifespan')


class FeatureTypeCombinationAdmin(admin.ModelAdmin):
    list_display = (
        'the_class', 'sub_class', 'type')


admin.site.register(Condition)
admin.site.register(Deterioration, DeteriorationAdmin)
admin.site.register(FeatureClass, FeatureClassAdmin)
admin.site.register(FeatureSubClass, FeatureSubClassAdmin)
admin.site.register(FeatureType, FeatureTypeAdmin)
admin.site.register(FeatureTypeCombination, FeatureTypeCombinationAdmin)
