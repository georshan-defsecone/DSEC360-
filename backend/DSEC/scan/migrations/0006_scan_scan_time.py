# Generated by Django 5.2 on 2025-07-04 06:35

import django.utils.timezone
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('scan', '0005_scan_scan_type'),
    ]

    operations = [
        migrations.AddField(
            model_name='scan',
            name='scan_time',
            field=models.DateTimeField(auto_now_add=True, default=django.utils.timezone.now),
            preserve_default=False,
        ),
    ]
