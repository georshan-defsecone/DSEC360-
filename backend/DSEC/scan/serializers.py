from rest_framework import serializers
from .models import Project, Scan
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
import csv
from io import StringIO
from rest_framework import serializers
from .models import Scan

class ScanSerializer(serializers.ModelSerializer):
    parsed_scan_result = serializers.SerializerMethodField()
    class Meta:
        model = Scan
        fields = '__all__'

    def get_parsed_scan_result(self, obj):
        if not obj.scan_result:
            return []
        try:
            csv_file = StringIO(obj.scan_result)
            reader = csv.DictReader(csv_file)
            return list(reader)
        except Exception:
            return []  # Or handle the error

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