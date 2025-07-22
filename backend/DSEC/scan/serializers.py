from rest_framework import serializers
from .models import Project, Scan
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
import csv
from io import StringIO
from rest_framework import serializers
from .models import Scan

# Serializer for Scan, now specifically handling versioned results for API output
class ScanSerializer(serializers.ModelSerializer):
    # This field will return the list of available version keys (e.g., ['v1', 'v2'])
    available_result_versions = serializers.SerializerMethodField()
    
    # This field will return the FULL DICTIONARY of all parsed versions: {'v1': [...], 'v2': [...]}
    # The frontend will use this to select versions.
    parsed_result_versions_data = serializers.SerializerMethodField() 
    
    # This field will return the data for the *currently active/latest* version directly as a list
    # The frontend uses this for the initial display.
    parsed_latest_scan_result = serializers.SerializerMethodField() 
    
    # To include project name directly in scan details
    project_name = serializers.CharField(source='project.project_name', read_only=True) 

    class Meta:
        model = Scan
        # List all fields explicitly to ensure control over what's included.
        # This explicitly excludes the raw `scan_result` JSONField from the main serialization,
        # as its content is managed by `parsed_result_versions_data`.
        fields = [
            'scan_id', 'scan_name', 'scan_author', 'scan_status', 'scan_type',
            'project', 'project_name', 'scan_data', 'scan_output', 'scan_time',
            'scan_result',
            'trash', 'scan_result_version', 
            'available_result_versions',     
            'parsed_result_versions_data',   
            'parsed_latest_scan_result',     
        ]

    def _parse_csv_or_return_list(self, data_content: str | list | None, scan_id: str, version_key: str) -> list[dict]:
        """
        Helper to parse CSV string to list of dicts, or return list if already parsed.
        Handles None, string errors, and non-list types.
        """
        if data_content is None:
            print(f"[DEBUG_SERIALIZER] No data content for {version_key} in scan {scan_id}.")
            return []
        
        if isinstance(data_content, list):
            # Data is already a parsed list of dicts (expected from recent saves)
            return data_content
        
        if isinstance(data_content, str):
            # Data is a CSV string (might be from older saves or specific content)
            try:
                csv_file = StringIO(data_content)
                reader = csv.DictReader(csv_file)
                parsed_list = list(reader)
                print(f"[DEBUG_SERIALIZER] Successfully parsed CSV for {version_key} in scan {scan_id}.")
                return parsed_list
            except Exception as e:
                print(f"[DEBUG_SERIALIZER] Error parsing CSV for {version_key} in scan {scan_id}: {e}")
                # You might want to return an error dict or specific info to frontend
                return [{'Error': f'CSV Parse Failed: {e}', 'RawData': data_content[:100] + '...'}] # Indicate parsing issue
        
        # Unexpected type stored in JSONField
        print(f"[DEBUG_SERIALIZER] Warning: Unexpected data type ({type(data_content)}) for {version_key} in scan {scan_id}. Expected str or list.")
        return []

    def get_available_result_versions(self, obj) -> list[str]:
        if not obj.scan_result:
            return []
        # Sort keys numerically (v1, v2, v10, not v1, v10, v2)
        return sorted(obj.scan_result.keys(), key=lambda x: int(x[1:]))

    def get_parsed_result_versions_data(self, obj) -> dict[str, list[dict]]:
        # This method iterates through all stored versions and processes each.
        processed_versions = {}
        if not obj.scan_result:
            return {}
        
        for version_key, raw_content in obj.scan_result.items():
            # Use the helper function to parse/return each version's data
            processed_versions[version_key] = self._parse_csv_or_return_list(raw_content, obj.scan_id, version_key)
        
        return processed_versions

    def get_parsed_latest_scan_result(self, obj) -> list[dict]:
        # This returns only the data for the latest version.
        # It relies on `parsed_result_versions_data` being correctly computed.
        
        if obj.scan_result_version <= 0 or not obj.scan_result:
            print(f"[DEBUG_SERIALIZER] No latest version or empty scan_result for scan {obj.scan_id}. Returning empty.")
            return []
        
        latest_version_key = f'v{obj.scan_result_version}'
        
        # Get the processed data for the specific latest version
        # Call the internal helper method `_parse_csv_or_return_list` directly for efficiency
        # This avoids re-computing all versions if only the latest is needed for this field.
        raw_latest_content = obj.scan_result.get(latest_version_key)
        return self._parse_csv_or_return_list(raw_latest_content, obj.scan_id, latest_version_key)


class ScanVersionSerializer(serializers.ModelSerializer):
    """
    Serializer for a Scan object that includes a specific parsed scan_result version.
    """
    parsed_scan_result_version = serializers.SerializerMethodField()
    project_name = serializers.CharField(source='project.project_name', read_only=True) # If you want project name directly

    class Meta:
        model = Scan
        # Include all original fields, and then our custom parsed field.
        # We'll also exclude 'scan_result' to avoid sending the entire JSON object
        # with all versions when only one is requested.
        exclude = ['scan_result'] # Exclude the raw JSONField to avoid redundancy

    def __init__(self, *args, **kwargs):
        # We'll pass the requested_version from the view context to the serializer
        self.requested_version = kwargs.pop('requested_version', None)
        super().__init__(*args, **kwargs)

    def get_parsed_scan_result(self, obj):
        if not obj.scan_result: # This checks if the JSONField is an empty dict {}
            return []
        
        latest_version_key = f'v{obj.scan_result_version}'
        # Directly retrieve the stored data, which is already a Python list/dict
        parsed_data = obj.scan_result.get(latest_version_key)

        # Ensure we return a list if the stored data is None or not a list (e.g., if it was a dict or string)
        if parsed_data is None:
            return []
        if isinstance(parsed_data, list):
            return parsed_data
        else:
            # Handle cases where `results` might be a single error string like "ERROR: ORA-..."
            # You might want to wrap non-list results in a list, or return a specific structure.
            # For now, let's just return it as is or an empty list if not a list
            # A more robust solution might involve specific serializers for different data types within scan_result.
            return [] # Or [parsed_data] if you want single items wrapped


class ProjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Project
        fields = '__all__'


class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)

        # Add custom claims to token payload
        token['username'] = user.username
        token['email'] = user.email
        token['is_admin'] = user.is_admin

        return token

    def validate(self, attrs):
        data = super().validate(attrs)

        # Include additional user info in the response body
        data['username'] = self.user.username
        data['email'] = self.user.email
        data['is_admin'] = self.user.is_admin

        return data