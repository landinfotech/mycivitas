# Generated by Django 2.2.15 on 2022-05-30 08:08

from django.db import migrations, models
import django.utils.timezone


class Migration(migrations.Migration):

    dependencies = [
        ('amlit', '0014_amlitproduct_best_value'),
    ]

    operations = [
        migrations.AddField(
            model_name='organisation',
            name='created_at',
            field=models.DateTimeField(default=django.utils.timezone.now, verbose_name='Created at '),
        ),
    ]
