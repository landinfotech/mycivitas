# Generated by Django 2.2.15 on 2021-04-17 01:16

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('amlit', '0005_organisation_subscription'),
    ]

    operations = [
        migrations.CreateModel(
            name='AmlitProduct',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('max_user', models.IntegerField(verbose_name='Max user')),
                ('product', models.IntegerField(default=0)),
            ],
        ),
    ]