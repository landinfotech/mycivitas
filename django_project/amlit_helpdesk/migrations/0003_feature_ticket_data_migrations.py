from django.db import migrations


def import_data(apps, schema_editor):
    FeatureTicket = apps.get_model("amlit_helpdesk", "FeatureTicket")

    for ticket in FeatureTicket.objects.all():
        if ticket.feature_id:
            ticket.features = [ticket.feature_id]
            ticket.save()


class Migration(migrations.Migration):
    dependencies = [
        ('amlit_helpdesk', '0002_auto_20210618_0228'),
    ]

    operations = [
        migrations.RunPython(import_data),
    ]
