__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '05/11/20'

from django.contrib import admin
from civitas.models.others.risk import POF, COF, Risk


class RiskAdmin(admin.ModelAdmin):
    list_display = ('pof', 'cof', 'value', 'level')


admin.site.register(POF)
admin.site.register(COF)
admin.site.register(Risk, RiskAdmin)
