__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '05/03/21'

from django.contrib import admin
from amlit_helpdesk.models.scheduler import SchedulerTemplate, SchedulerOrganisation
from amlit_helpdesk.forms.scheduler_template import SchedulerTemplateForm


class SchedulerTemplateAdmin(admin.ModelAdmin):
    list_display = ('feature_type', 'recurring_type', 'title', 'description')
    form = SchedulerTemplateForm

    def feature_type(self, object: SchedulerTemplate):
        return object.feature_type_combination_str

    # regular stuff
    class Media:
        js = (
            'libs/jquery.js/3.4.1/jquery.min.js',
            'libs/jquery-ui/1.12.1/jquery-ui.js',
            'js/forms/widget/recurring_type.js',
        )


class SchedulerOrganisationAdmin(admin.ModelAdmin):
    list_display = ('feature_type', 'organisation', 'recurring_ticket')

    def feature_type(self, object: SchedulerTemplate):
        return object.feature_type_combination_str


admin.site.register(SchedulerTemplate, SchedulerTemplateAdmin)
admin.site.register(SchedulerOrganisation, SchedulerOrganisationAdmin)
