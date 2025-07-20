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
    scan_type = models.CharField(max_length=100)
    scan_author = models.CharField(max_length=255)
    scan_status = models.CharField(max_length=50)
    scan_data = models.JSONField(null=True, blank=True)
    scan_result = models.JSONField(default=dict, null=True, blank=True) # Stores all versions
    scan_output = models.JSONField(null=True, blank=True)
    scan_time = models.DateTimeField(auto_now_add=True)
    trash = models.BooleanField(default=False)
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='scans')

    # This still tracks the LATEST version for convenience, but you'll query scan_result for others
    scan_result_version = models.IntegerField(default=0) 

    def __str__(self):
        return self.scan_name
    
    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)

    def update_scan_result(self, new_data): # Renamed `new_csv_data` to `new_data`
        """
        Updates the scan_result with a new version.
        `new_data` can be any JSON-serializable Python object (dict, list, string, etc.).
        """
        if self.pk is None:
            raise ValueError("Cannot update scan_result on a Scan instance that hasn't been saved yet.")

        self.scan_result_version += 1
        version_key = f'v{self.scan_result_version}'
        
        if self.scan_result is None: 
            self.scan_result = {}
            
        self.scan_result[version_key] = new_data # Store the new_data directly
        self.save()

    def get_specific_scan_result_version(self, version_number):
        """
        Retrieves a specific version's data (which is now JSON/Python object).
        """
        version_key = f'v{version_number}'
        return self.scan_result.get(version_key) # Returns the stored JSON data

    def get_all_scan_result_versions(self):
        """
        Returns a dictionary of all stored scan_result versions (e.g., {'v1': 'csv_data', 'v2': 'csv_data'}).
        """
        return self.scan_result if self.scan_result else {}