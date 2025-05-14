from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.decorators import api_view, permission_classes
from rest_framework import status
from rest_framework.response import Response


#from rest_framework.permissions import IsAuthenticated
from rest_framework.permissions import AllowAny

import os
from django.conf import settings
import pandas as pd





    


# Create your views here.
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers import MyTokenObtainPairSerializer
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny,IsAuthenticated
from rest_framework.response import Response
from .models import User,Config
from .serializers import UserSerializer,RegisterSerializer
from .permissions import IsAdminUserCustom
from rest_framework import status
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers import MyTokenObtainPairSerializer,UserUpdateSerializer
import os
import json
from django.http import JsonResponse

SETTINGS_FILE = os.path.join(os.path.dirname(__file__), 'usersettings.json')

class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer

@api_view(['GET'])
@permission_classes([IsAdminUserCustom])
def get_all_users(request):
    users = User.objects.all()  # Get all users
    serializer = UserSerializer(users, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAdminUserCustom])
def create_user(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])  # or [IsAdminUserCustom] if it's restricted
def get_authenticated_user(request):
    user = request.user  # Extracted directly from the JWT token
    serializer = UserSerializer(user)
    return Response(serializer.data)

@api_view(['PUT'])
@permission_classes([IsAdminUserCustom])  # Make sure the user is authenticated
def update_user(request):
    user = request.user  # Get the user from the request

    # Use the update serializer to validate and update only specific fields
    serializer = UserUpdateSerializer(user, data=request.data, partial=True)
    
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)




    

@api_view(['POST'])
@permission_classes([IsAdminUserCustom])
def save_proxy_settings(request):
    proxy_data = request.data

    # Load existing settings or create new structure
    existing_data = {}
    if os.path.exists(SETTINGS_FILE):
        with open(SETTINGS_FILE, 'r') as f:
            existing_data = json.load(f)

    # Update proxy section
    existing_data['proxy'] = proxy_data

    # Save back to JSON file
    with open(SETTINGS_FILE, 'w') as f:
        json.dump(existing_data, f, indent=2)

    return Response({'message': 'Proxy settings saved successfully'}, status=status.HTTP_200_OK)

@api_view(['GET'])
@permission_classes([IsAdminUserCustom])
def get_proxy_settings(request):
    if os.path.exists(SETTINGS_FILE):
        with open(SETTINGS_FILE, 'r') as f:
            data = json.load(f)
            proxy_settings = data.get('proxy', {})
            return Response(proxy_settings, status=status.HTTP_200_OK)
    else:
        return Response({}, status=status.HTTP_200_OK)
    


@api_view(['POST'])
@permission_classes([IsAdminUserCustom])
def save_smtp_settings(request):
    smtp_data = request.data

    # Load existing settings or create new structure
    existing_data = {}
    if os.path.exists(SETTINGS_FILE):
        with open(SETTINGS_FILE, 'r') as f:
            existing_data = json.load(f)

    # Update smtp section
    existing_data['smtp'] = smtp_data

    # Save back to JSON file
    with open(SETTINGS_FILE, 'w') as f:
        json.dump(existing_data, f, indent=2)

    return Response({'message': 'smtp settings saved successfully'}, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAdminUserCustom])
def get_smtp_settings(request):
    if os.path.exists(SETTINGS_FILE):
        with open(SETTINGS_FILE, 'r') as f:
            data = json.load(f)
            smtp_settings = data.get('smtp', {})
            return Response(smtp_settings, status=status.HTTP_200_OK)
    else:
        return Response({}, status=status.HTTP_200_OK)
    

@api_view(['GET'])
@permission_classes([IsAdminUserCustom])
def get_ldap_settings(request):
    if os.path.exists(SETTINGS_FILE):
        with open(SETTINGS_FILE, 'r') as f:
            data = json.load(f)
            ldap_settings = data.get('ldap', {})
            return Response(ldap_settings, status=status.HTTP_200_OK)
    else:
        return Response({}, status=status.HTTP_200_OK)
    

@api_view(['POST'])
@permission_classes([IsAdminUserCustom])
def save_ldap_settings(request):
    ldap_data = request.data

    # Load existing settings or create new structure
    existing_data = {}
    if os.path.exists(SETTINGS_FILE):
        with open(SETTINGS_FILE, 'r') as f:
            existing_data = json.load(f)

    # Update smtp section
    existing_data['ldap'] = ldap_data

    # Save back to JSON file
    with open(SETTINGS_FILE, 'w') as f:
        json.dump(existing_data, f, indent=2)

    return Response({'message': 'ldap settings saved successfully'}, status=status.HTTP_200_OK)


def load_json_to_db(request):
    # Path to the JSON file on your backend
    json_file_path = SETTINGS_FILE

    try:
        # Open and load the JSON file
        with open(json_file_path, 'r') as f:
            data = json.load(f)

        # Extract the JSON data, and only update if the field exists
        proxy_data = data.get('proxy', None)
        smtp_data = data.get('smtp', None)
        ldap_data = data.get('ldap', None)

        # Try to get the existing Config record (if it exists)
        config, created = Config.objects.get_or_create(id=1)

        # If the record was created, then insert the values
        if created:
            if proxy_data is not None:
                config.proxy = proxy_data
            if smtp_data is not None:
                config.smtp = smtp_data
            if ldap_data is not None:
                config.ldap = ldap_data
            config.save()
            message = "Data inserted successfully"
        else:
            # If the record already exists, update only the fields that are provided
            updated = False

            if proxy_data is not None and config.proxy != proxy_data:
                config.proxy = proxy_data
                updated = True
            if smtp_data is not None and config.smtp != smtp_data:
                config.smtp = smtp_data
                updated = True
            if ldap_data is not None and config.ldap != ldap_data:
                config.ldap = ldap_data
                updated = True

            # Save if any data was updated
            if updated:
                config.save()
                message = "Data updated successfully"
            else:
                message = "No changes detected"

        return JsonResponse({"status": "success", "message": message, "config_id": config.id}, status=200)

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=500)