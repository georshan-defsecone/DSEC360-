from django.db import models

class Project(models.Model):
    project_id = models.CharField(primary_key=True)
    project_name = models.CharField(max_length=255)
    project_author = models.CharField(max_length=255)
    trash = models.BooleanField(default=False)


    def __str__(self):
        return self.project_name


class Scan(models.Model):
    scan_id = models.CharField(primary_key=True, max_length=100)
    scan_name = models.CharField(max_length=255)
    scan_author = models.CharField(max_length=255)
    scan_status = models.CharField(max_length=50)
    scan_data = models.JSONField(null=True, blank=True)  # <-- New JSON field added here
    scan_result = models.TextField(null=True, blank=True)
    trash = models.BooleanField(default=False)
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='scans')


    def __str__(self):
        return self.scan_name

