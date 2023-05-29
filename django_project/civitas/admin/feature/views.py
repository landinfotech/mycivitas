from django.contrib import admin
from civitas.models.view.reporter_data import ReporterData


class ReporterDataAdmin(admin.ModelAdmin):
    list_display = ReporterData.FIELDS

    def has_change_permission(self, request, obj=None):
        return False


admin.site.register(ReporterData, ReporterDataAdmin)
