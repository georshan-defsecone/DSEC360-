# Generated by Django 5.2 on 2025-06-23 05:43

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('scan', '0002_scan_scan_data'),
    ]

    operations = [
        migrations.AddField(
            model_name='scan',
            name='scan_result',
            field=models.TextField(blank=True, null=True),
        ),
    ]
