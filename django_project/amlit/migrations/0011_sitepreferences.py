# Generated by Django 2.2.15 on 2021-08-04 09:59

import amlit.models.preferences
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('amlit', '0010_user_avatar'),
    ]

    operations = [
        migrations.CreateModel(
            name='SitePreferences',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('feature_info_format', amlit.models.preferences.OrderedJSONField(default=dict, help_text='Format get feature info that rendered on the frontend. This is used for grouping specific keys from the getFeatureInfo. Use the key in this json as the group name, and the value is in array, with the key of getFeatureInfo in array.')),
            ],
            options={
                'abstract': False,
            },
        ),
    ]
