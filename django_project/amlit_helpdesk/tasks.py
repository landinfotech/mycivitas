from core.celery import app
from amlit_helpdesk.models.recurring_ticket import RecurringTicket


@app.task
def recurring_tickets_check():
    for recurring_ticket in RecurringTicket.objects.all():
        recurring_ticket.check_recurring_event()
