# Generated by Django 2.2.15 on 2021-04-16 23:12

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('amlit', '0003_auto_20210405_0646'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='subscription',
            name='organisation',
        ),
        migrations.RemoveField(
            model_name='subscription',
            name='subscription_plan',
        ),
        migrations.RemoveField(
            model_name='subscriptionplan',
            name='currency',
        ),
        migrations.RemoveField(
            model_name='subscriptionplan',
            name='plan',
        ),
        migrations.RemoveField(
            model_name='organisation',
            name='subscription',
        ),
        migrations.DeleteModel(
            name='Currency',
        ),
        migrations.DeleteModel(
            name='Plan',
        ),
        migrations.DeleteModel(
            name='Subscription',
        ),
        migrations.DeleteModel(
            name='SubscriptionPlan',
        ),
    ]
