from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.decorators import api_view, permission_classes
from rest_framework import status
from rest_framework.response import Response
from .models import Project, Scan
from .serializers import ProjectSerializer, ScanSerializer
#from rest_framework.permissions import IsAuthenticated
from rest_framework.permissions import AllowAny
import uuid
from io import BytesIO
import os
from django.conf import settings
import pandas as pd
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers import MyTokenObtainPairSerializer
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny,IsAuthenticated
from rest_framework.response import Response
from .permissions import IsAdminUserCustom
from rest_framework import status
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers import MyTokenObtainPairSerializer
from django.db.models import Q
from django.views.decorators.csrf import csrf_exempt
from startScan.views import database_config_audit, windows_config_audit, linux_config_audit
from startScan.views import windows_compromise_assesment
from startScan.views import download_script
from django.http import FileResponse
import json
import mimetypes

@api_view(['POST'])
@permission_classes([AllowAny])
def add_MyProjectsView(request):
    serializer = ScanSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
@permission_classes([AllowAny])
def update_MyProjectsView(request, scan_id):
    try:
        scan = Scan.objects.get(scan_id=scan_id)
        scan.trash = True
        scan.save()
        return Response({"message": "Scan moved to trash"}, status=status.HTTP_200_OK)
    except Scan.DoesNotExist:
        return Response({"error": "Scan not found"}, status=status.HTTP_404_NOT_FOUND)
    

@api_view(['GET'])
@permission_classes([AllowAny])
def trashed_scans_view(request):
    trashed_scans = Scan.objects.filter(trash=True)
    serializer = ScanSerializer(trashed_scans, many=True)
    return Response(serializer.data)

# Create your views here.




class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer

@api_view(['GET'])
@permission_classes([AllowAny])
def get_compliance_data(request, os_name):
    try:
        file_path = os.path.join(settings.BASE_DIR, 'scan', 'data', 'Configuration_Audit - Copy.xlsx')

        if not os.path.exists(file_path):
            return Response({'error': 'File not found'}, status=404)

        df = pd.read_excel(file_path)
        print("DataFrame loaded successfully!")
        print(os_name)
        df = df[df['Configuration Name'].str.lower() == os_name.lower()]
        json_data = df.to_dict(orient='records')
        return Response(json_data, status=200)

    except Exception as e:
        print("Error while loading Excel:", e)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_compromise_assessment_data(request, os_name):
    try:
        file_path = os.path.join(settings.BASE_DIR, 'scan', 'data', 'Compromise_Assessment.xlsx')

        if not os.path.exists(file_path):
            return Response({'error': 'File not found'}, status=404)

        df = pd.read_excel(file_path)
        print("DataFrame loaded successfully!")

        df = df[df['OS'].str.lower() == os_name.lower()]
        json_data = df.to_dict(orient='records')
        return Response(json_data, status=200)

    except Exception as e:
        print("Error while loading Excel:", e)
        return Response({'error': str(e)}, status=500)
    

#get projects
@api_view(['GET'])
@permission_classes([IsAuthenticated])  # Only authenticated users
def get_projects_view(request):
    user = request.user
    projects = Project.objects.filter(
        Q(project_author=user.username) | Q(scans__scan_author=user.username),
        trash=False
    ).distinct()
    serializer = ProjectSerializer(projects, many=True)
    return Response(serializer.data)


#get project by id
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_project_by_id(request, project_id):
    try:
        project = Project.objects.get(project_id=project_id)
        serializer = ProjectSerializer(project)
        return Response(serializer.data)
    except Project.DoesNotExist:
        return Response({'error': 'Project not found'}, status=status.HTTP_404_NOT_FOUND)
    
#get projects (for allprojects in frontend)
@api_view(['GET'])
@permission_classes([IsAdminUserCustom])
def get_all_projects_view(request):
    projects = Project.objects.filter(trash=False)  # Only non-trashed projects
    serializer = ProjectSerializer(projects, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])  # Only authenticated users can create a project
def create_project_view(request):
    # Ensure that the logged-in user is set as the project_author
    data = request.data.copy()
    data['project_author'] = request.user.id  # Or you can use request.user.username

    serializer = ProjectSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


#trash project
@api_view(['PUT'])
@permission_classes([IsAuthenticated])  
def update_project_view(request, project_id):
    try:
        project = Project.objects.get(project_id=project_id)
    except Project.DoesNotExist:
        return Response({'error': 'Project not found'}, status=status.HTTP_404_NOT_FOUND)

    serializer = ProjectSerializer(project, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


#trashed projects
@api_view(['GET'])
@permission_classes([IsAuthenticated])  
def trashed_projects_view(request):
    user = request.user

    if user.is_admin:
        # If the user is an admin, fetch all trashed projects
        trashed_projects = Project.objects.filter(trash=True)
    else:
        trashed_projects = Project.objects.filter(trash=True, project_author=user.username)
    serializer = ProjectSerializer(trashed_projects, many=True)
    #to check 
    # print(f"Logged in user: {user.username}")
    # for p in Project.objects.filter(trash=True):
    #     print(f"{p.project_id}: {p.project_author}")

    return Response(serializer.data)

#remove (trashed) project and thier related scans from DB
@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_project_view(request, project_id):
    try:
        project = Project.objects.get(project_id=project_id)
    except Project.DoesNotExist:
        return Response({'error': 'Project not found'}, status=status.HTTP_404_NOT_FOUND)

    # Check if the user is the author of the project or an admin
    if request.user.username != project.project_author and not request.user.is_admin:
        return Response({'error': 'You do not have permission to delete this project'}, status=status.HTTP_403_FORBIDDEN)

    # Delete related scans
    project.scans.all().delete()  # assumes related_name='scans' on the FK

    # Delete the project
    project.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)


#remove (trashed) all projects and thier related scans from DB
@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_all_projects_view(request):
    try:
        trashed_projects = Project.objects.filter(trash=True)
        for project in trashed_projects:
            project.scans.all().delete()  # Delete all related scans
            project.delete()  # Delete the project itself
        return Response({"message": "All trashed projects and related scans deleted."}, status=200)
    except Exception as e:
        return Response({"error": str(e)}, status=400)

#get scans
@api_view(['GET'])
@permission_classes([AllowAny])
def get_scans_view(request):
    scans = Scan.objects.filter(trash=False)
    serializer = ScanSerializer(scans, many=True)
    return Response(serializer.data)

#create scan only in djangorestframework
@api_view(['POST'])
@permission_classes([AllowAny])
def create_scan_view(request):
    serializer = ScanSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

#trash scan
@api_view(['PUT'])
@permission_classes([AllowAny])
def update_scan_view(request, pk):
    try:
        scan = Scan.objects.get(pk=pk)
    except Scan.DoesNotExist:
        return Response({'error': 'Scan not found'}, status=status.HTTP_404_NOT_FOUND)

    serializer = ScanSerializer(scan, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

#get scans by project id
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_project_scans_view(request, project_id):
    user = request.user

    try:
        project = Project.objects.get(project_id=project_id, trash=False)
    except Project.DoesNotExist:
        return Response({'error': 'Project not found'}, status=status.HTTP_404_NOT_FOUND)

    if user.is_admin:
        # Admin: show all scans for the project
        scans = Scan.objects.filter(project_id=project_id, trash=False)
    else:
        # Normal user: show only their scans in the project
        scans = Scan.objects.filter(
            project_id=project_id,
            scan_author=user.username,
            trash=False
        )

    serializer = ScanSerializer(scans, many=True)
    return Response(serializer.data)

#get scans by user logged in for result page
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_scans_view(request):
    user = request.user
    scans = Scan.objects.filter(scan_author=user.username, trash=False)
    serializer = ScanSerializer(scans, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([AllowAny])
def post_scan_file(request):
    if request.method == 'POST':
        file = request.FILES.get('file')
        if not file:
            return Response({'error': 'No file provided'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate file extension
        allowed_extensions = {'.txt', '.pdf', '.doc', '.docx', '.xls', '.xlsx'}
        file_ext = os.path.splitext(file.name)[1].lower()
        if file_ext not in allowed_extensions:
            return Response({'error': 'Invalid file type'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Create a secure upload directory if it doesn't exist
        upload_dir = os.path.join(settings.MEDIA_ROOT, 'target')
        os.makedirs(upload_dir, exist_ok=True)
        
        # Generate safe filename
        safe_filename = f"{uuid.uuid4()}{file_ext}"
        file_path = os.path.join(upload_dir, safe_filename)
        
        try:
            # Save file safely
            with open(file_path, 'wb+') as destination:
                for chunk in file.chunks():
                    destination.write(chunk)
            return Response({
                'message': 'File uploaded successfully',
                'filename': safe_filename
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response({
                'error': f'Error saving file: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    return Response({'error': 'Invalid request method'}, status=status.HTTP_405_METHOD_NOT_ALLOWED)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_scan_result_view(request, project_name, scan_name):
    user = request.user

    try:
        # Find project by name
        project = Project.objects.get(project_name=project_name, trash=False)
    except Project.DoesNotExist:
        return Response({'error': 'Project not found'}, status=status.HTTP_404_NOT_FOUND)

    try:
        # Filter scan by name and project
        if user.is_admin:
            scan = Scan.objects.get(scan_name=scan_name, project=project, trash=False)
        else:
            scan = Scan.objects.get(scan_name=scan_name, project=project, scan_author=user.username, trash=False)
    except Scan.DoesNotExist:
        return Response({'error': 'Scan not found'}, status=status.HTTP_404_NOT_FOUND)

    if not scan.scan_result:
        return Response({'error': 'Scan result is empty or missing.'}, status=status.HTTP_204_NO_CONTENT)

    # Return scan_result as a CSV stream (not downloaded)
    csv_stream = BytesIO(scan.scan_result.encode('utf-8'))
    return FileResponse(csv_stream, content_type='text/csv')

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def create_scan(request):
    print("entered create scan")
    data = request.data.copy()

    project_name = data.get("project_name")
    scan_author = data.get("scan_author", "unknown")
    scan_name = data.get("scan_name")  
   
    if not project_name:
        return Response({"error": "project_name is required."}, status=status.HTTP_400_BAD_REQUEST)

    if not scan_name:
        return Response({"error": "scanName is required."}, status=status.HTTP_400_BAD_REQUEST)

    project, created = Project.objects.get_or_create(
        project_name=project_name,
        defaults={
            "project_id": str(uuid.uuid4()),
            "project_author": scan_author,
            "trash": False,
        }
    )

    # ✅ Check if a scan with the same name already exists in the project
    if Scan.objects.filter(scan_name=scan_name, project=project, trash=False).exists():
        return Response(
            {"error": f"Scan with name '{scan_name}' already exists in project '{project_name}'."},
            status=status.HTTP_400_BAD_REQUEST
        )

    data["project"] = project.pk
    data["scan_id"] = str(uuid.uuid4())
    data["scan_name"] = scan_name  # map frontend key to model field
    data.pop("project_name", None)
    data.pop("scanName", None)

    serializer = ScanSerializer(data=data)

    if serializer.is_valid():
        serializer.save()

        scan_data = data.get("scan_data", {})
        try:
            result = launch_scan(scan_data)
            if result is None:
                print("[!] launch_scan() returned None")
                return Response({"error": "Scan execution failed"}, status=500)

            file_path, output_json_path = result
            print("[DEBUG] Returned file_path:", file_path)
            print("[DEBUG] file exists:", os.path.exists(file_path))
        except Exception as e:
            print("[!] launch_scan() failed:", e)
            return Response({"error": "Scan execution failed", "details": str(e)}, status=500)

        category = scan_data.get("category", "").strip().lower()
        audit_method = scan_data.get("auditMethod", "").strip().lower()
        scan_instance = Scan.objects.get(scan_id=data["scan_id"])

        # Save output.json content to scan_output field
        if output_json_path and os.path.exists(output_json_path):
            with open(output_json_path, "r", encoding="utf-8") as f:
                try:
                    output_data = json.load(f)
                    scan_instance.scan_output = output_data
                    scan_instance.save()
                except json.JSONDecodeError:
                    print("[!] Failed to decode output.json")

        if file_path and os.path.exists(file_path):
            # Determine filename based on audit type
            if audit_method == "agent" and category == "linux":
                version = scan_data.get("complianceCategory", "").strip().replace(" ", "_")
                filename = f"{version}_audit_script.sh"
            else:
                filename = os.path.basename(file_path)

            if audit_method != "agent":
                with open(file_path, "r", encoding="utf-8") as f:
                    csv_text = f.read()

                scan_instance.scan_result = csv_text
                scan_instance.save()

                csv_stream = BytesIO(csv_text.encode("utf-8"))
                return FileResponse(csv_stream, content_type="text/csv")

            else:
                mime_type, _ = mimetypes.guess_type(file_path)
                mime_type = mime_type or "application/octet-stream"

                return FileResponse(
                    open(file_path, "rb"),
                    as_attachment=True,
                    filename=filename,
                    content_type=mime_type
                )

        return Response({
            "message": "Scan created successfully.",
            "scan": serializer.data
        }, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



import re

def launch_scan(scan_data):
    print("[*] Entered launch_scan()")
    

    # Normalize and extract values from scan_data
    scan_type = (scan_data.get("scanType") or "").strip().lower().replace(" ", "").replace("_", "")
    print("[DEBUG] scan_type:", scan_type)

    os_name = (scan_data.get("os") or "").strip().lower()
    print("[DEBUG] os_name:", os_name)

    auth_type = (scan_data.get("auditMethod") or "").strip().lower()
    category=(scan_data.get("category")or"").strip().lower()
    compliance_name=(scan_data.get("complianceCategory") or "").strip().lower()

    standard = scan_data.get("complianceSecurityStandard")
    # Remove all non-alphanumeric characters including underscores, then lowercase
    normalized_compliance = re.sub(r'[\W_]+', '', compliance_name or "").lower()
    print(scan_data)
    print("[DEBUG] auth_type:", auth_type)
    category = (scan_data.get("category") or "").strip().lower()
    print("[DEBUG] category:", category)

    audit_method = (scan_data.get("auditMethod") or "").strip().lower()


    compliance_name = (scan_data.get("complianceCategory") or "").strip().lower()
    standard = scan_data.get("complianceSecurityStandard")

    # Remove all non-alphanumeric characters including underscores, then lowercase
    normalized_compliance = re.sub(r'[\W_]+', '', compliance_name or "").lower()
    print("[DEBUG] scan_data received:", scan_data)

    if scan_type == "configurationaudit":

        if category=="database":
           return database_config_audit(scan_data)
           

        if category=="windows":
            
            return windows_config_audit(scan_data)

        if category == "linux":
            return None, None

        if category=="firewall":
            return None,None
        
        if category == "firewall":
            return None, None

    elif scan_type == "compromiseassessment":
        if category == "windows":
            return windows_compromise_assesment(scan_data)

    
        if category == "linux":
            return None, None

           
    return None, None  