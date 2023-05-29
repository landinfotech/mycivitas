from rest_framework import serializers
from django.shortcuts import reverse
from amlit_helpdesk.models.scheduler import (
    SchedulerTemplate, SchedulerOrganisation
)


class SchedulerTemplateSerializer(serializers.ModelSerializer):
    id = serializers.SerializerMethodField()
    feature_type_combination_id = serializers.SerializerMethodField()
    feature_type_combination_str = serializers.SerializerMethodField()
    active = serializers.SerializerMethodField()

    def get_id(self, obj: SchedulerTemplate):
        return None

    def get_feature_type_combination_id(self, obj: SchedulerTemplate):
        return obj.feature_type_combination

    def get_feature_type_combination_str(self, obj: SchedulerTemplate):
        return obj.feature_type_combination_str

    def get_active(self, obj: SchedulerTemplate):
        return False

    class Meta:
        model = SchedulerTemplate
        fields = '__all__'


class SchedulerOrganisationSerializer(serializers.ModelSerializer):
    feature_type_combination_id = serializers.SerializerMethodField()
    feature_type_combination_str = serializers.SerializerMethodField()
    active = serializers.SerializerMethodField()
    title = serializers.SerializerMethodField()
    description = serializers.SerializerMethodField()
    operator = serializers.SerializerMethodField()
    operator_id = serializers.SerializerMethodField()
    recurring_type = serializers.SerializerMethodField()
    ticket_link = serializers.SerializerMethodField()

    def get_feature_type_combination_id(self, obj: SchedulerOrganisation):
        return obj.feature_type_combination

    def get_feature_type_combination_str(self, obj: SchedulerOrganisation):
        return obj.feature_type_combination_str

    def get_active(self, obj: SchedulerOrganisation):
        if obj.recurring_ticket:
            return obj.recurring_ticket.active
        else:
            return False

    def get_title(self, obj: SchedulerOrganisation):
        if obj.recurring_ticket:
            return obj.recurring_ticket.last_ticket.title
        else:
            return ''

    def get_description(self, obj: SchedulerOrganisation):
        if obj.recurring_ticket:
            return obj.recurring_ticket.last_ticket.description
        else:
            return ''

    def get_operator(self, obj: SchedulerOrganisation):
        if obj.recurring_ticket:
            return obj.recurring_ticket.last_ticket.assigned_to
        else:
            return ''

    def get_operator_id(self, obj: SchedulerOrganisation):
        if obj.recurring_ticket and obj.recurring_ticket.last_ticket.assigned_to:
            return obj.recurring_ticket.last_ticket.assigned_to.id
        else:
            return ''

    def get_recurring_type(self, obj: SchedulerOrganisation):
        if obj.recurring_ticket:
            return obj.recurring_ticket.recurring_type
        else:
            return ''

    def get_ticket_link(self, obj: SchedulerOrganisation):
        if obj.recurring_ticket:
            return reverse(
                'helpdesk:view',
                args=[obj.recurring_ticket.last_ticket.id])
        else:
            return ''

    class Meta:
        model = SchedulerOrganisation
        fields = '__all__'
