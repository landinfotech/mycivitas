from rest_framework import serializers

from helpdesk.models import Ticket
from helpdesk.serializers import DatatablesTicketSerializer


class DatatablesTicketExtendedSerializer(DatatablesTicketSerializer):
    priority_text = serializers.SerializerMethodField()

    class Meta:
        model = Ticket
        # fields = '__all__'
        fields = ('ticket', 'id', 'priority', 'title', 'queue', 'status',
                  'created', 'due_date', 'assigned_to', 'submitter', 'row_class',
                  'time_spent', 'kbitem', 'priority_text', 'start_date')

    def get_priority_text(self, obj: Ticket):
        return obj.get_priority_display()
