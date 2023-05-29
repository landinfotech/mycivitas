from __future__ import absolute_import

from celery import Celery
from celery.schedules import crontab

app = Celery('civitas')

app.config_from_object('django.conf:settings', namespace="CELERY")
app.autodiscover_tasks()

app.conf.beat_schedule = {
    'check-recurring-tickets-day': {
        'task': 'amlit_helpdesk.tasks.recurring_tickets_check',
        'schedule': crontab(hour=12, minute=00)
    },
    'check-recurring-tickets-night': {
        'task': 'amlit_helpdesk.tasks.recurring_tickets_check',
        'schedule': crontab(hour=0, minute=00)
    },
}


@app.task(bind=True)
def debug_task(self):
    print('Request: {0!r}'.format(self.request))
