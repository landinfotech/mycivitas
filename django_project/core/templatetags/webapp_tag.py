from django import template
from django.contrib.auth import get_user_model
from helpdesk.models import Ticket
from amlit_helpdesk.models.feature_ticket import FeatureTicket
from amlit_helpdesk.models.recurring_ticket import RecurringTicket
from amlit.models.user import UserByString

register = template.Library()
User = get_user_model()


@register.simple_tag
def string_to_css_class(string: str):
    return string.replace(' ', '-').lower()


@register.simple_tag
def get_user_by_username(username):
    return UserByString(username)


@register.simple_tag
def get_feature_ticket(ticket: Ticket):
    try:
        return ticket.featureticket
    except FeatureTicket.DoesNotExist:
        return None


@register.simple_tag
def get_recurring_ticket(ticket: Ticket):
    try:
        return ticket.last_ticket
    except (RecurringTicket.DoesNotExist,):
        return None


@register.simple_tag
def is_image(url: str) -> bool:
    """ Check url if it is image or not """
    extensions = {".jpg", ".png", ".gif", ".jpeg", ".JPG", ".PNG", ".GIF", ".JPEG"}
    return any(url.endswith(ext) for ext in extensions)
