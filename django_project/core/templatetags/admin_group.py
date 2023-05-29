from django import template
from django.conf import settings

try:
    ADMIN_GROUP = settings.ADMIN_GROUP
except AttributeError:
    ADMIN_GROUP = {}
register = template.Library()


@register.simple_tag
def grouping_models(app):
    if app['app_label'] in ADMIN_GROUP.keys():
        admin_group = ADMIN_GROUP[app['app_label']]
        groups = []
        for key, value in admin_group.items():
            group = {
                'name': key,
                'models': []
            }
            for object_name in value:
                for model in app['models']:
                    if model['object_name'] == object_name:
                        group['models'].append(model)
            groups.append(group)
        return groups
    return None
