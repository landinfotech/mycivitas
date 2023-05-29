__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '05/11/20'

from django.contrib import admin
from civitas.models.capital_project import CapitalProject, CapitalProjectFeatureCombination


class CapitalProjectFeatureInline(admin.TabularInline):
    model = CapitalProjectFeatureCombination


class CapitalProjectAdmin(admin.ModelAdmin):
    list_display = ('name', 'year', 'proforma_cost', 'community')
    inlines = [CapitalProjectFeatureInline]


admin.site.register(CapitalProject, CapitalProjectAdmin)
