from django.contrib.auth import get_user_model
from django.contrib.postgres.fields import JSONField
from django.db import models
from core.models.singleton import SingletonModel
from helpdesk.models import Queue

User = get_user_model()


class OrderedJSONField(JSONField):

    def db_type(self, connection):
        return 'json'


class SitePreferences(SingletonModel):
    """ Setting specifically for amlit """

    feature_info_format = OrderedJSONField(
        default=dict,
        help_text='Format get feature info that rendered on the frontend. '
                  'This is used for grouping specific keys from the getFeatureInfo. '
                  'Use the key in this json as the group name, and the value is in array, with the key of getFeatureInfo in array.'
    )
    recurred_queues = models.ManyToManyField(
        Queue, blank=True, null=True,
        help_text='The Queue list that can be create the recurring tickets.'
    )

    @property
    def recurred_queues_ids(self):
        return list(self.recurred_queues.values_list('id', flat=True))

    @staticmethod
    def preferences() -> "SitePreferences":
        return SitePreferences.load()
