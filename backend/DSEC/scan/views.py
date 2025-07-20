from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.decorators import api_view, permission_classes
from rest_framework import status
from rest_framework.response import Response
from .models import Project, Scan
from .serializers import ProjectSerializer, ScanSerializer, ScanVersionSerializer
#from rest_framework.permissions import IsAuthenticated
from rest_framework.permissions import AllowAny
from django.http import JsonResponse
import uuid
from io import BytesIO,StringIO
import os
from pathlib import Path
import csv
import io
import traceback
from django.conf import settings
import pandas as pd
import openpyxl
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
from startScan.views import convert_csv_to_excel
from django.http import FileResponse
import json
import mimetypes
from django.shortcuts import get_object_or_404
from startScan.Configuration_Audit.Database.ORACLE import oraclevalidate as oraclevalidator

def sanitize(name):
    return re.sub(r'\W+', '', name).lower()


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
    except Scan.DoesNotExist:
        return Response({"error": "Scan not found"}, status=status.HTTP_404_NOT_FOUND)

    trash_value = request.data.get('trash')
    if trash_value is None:
        return Response({"error": "Missing 'trash' value in request body"}, status=status.HTTP_400_BAD_REQUEST)

    scan.trash = trash_value
    scan.save()
    return Response({"message": f"Scan trash status updated to {scan.trash}"}, status=status.HTTP_200_OK)
    



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


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def trashed_scans_view(request):
    user = request.user

    if user.is_admin:
        trashed_scans = Scan.objects.filter(trash=True)
    else:
        trashed_scans = Scan.objects.filter(trash=True, scan_author=user.username)

    serializer = ScanSerializer(trashed_scans, many=True)
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

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_scan_view(request, scan_id):
    try:
        scan = Scan.objects.get(scan_id=scan_id)
    except Scan.DoesNotExist:
        return Response({'error': 'Scan not found'}, status=status.HTTP_404_NOT_FOUND)

    # Check if the user is the author of the scan or an admin
    if request.user.username != scan.scan_author and not request.user.is_admin:
        return Response({'error': 'You do not have permission to delete this scan'}, status=status.HTTP_403_FORBIDDEN)

    # Delete the scan
    scan.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)

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
        project = Project.objects.get(project_name=project_name, trash=False)
    except Project.DoesNotExist:
        return Response({'error': 'Project not found'}, status=status.HTTP_404_NOT_FOUND)

    try:
        if user.is_admin:
            scan = Scan.objects.get(scan_name=scan_name, project=project, trash=False)
        else:
            scan = Scan.objects.get(scan_name=scan_name, project=project, scan_author=user.username, trash=False)
    except Scan.DoesNotExist:
        return Response({'error': 'Scan not found or you do not have permission to view it.'}, status=status.HTTP_404_NOT_FOUND)

    serializer = ScanSerializer(scan)
    
    # Return the entire serialized scan data, which includes parsed_scan_result
    # This aligns with the frontend's expectation of `response.data` having `parsed_scan_result`
    return Response(serializer.data, status=status.HTTP_200_OK)




@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_project_details(request, project_id):
    try:
        project = Project.objects.get(project_id=project_id)
    except Project.DoesNotExist:
        return Response({"detail": "Project not found."}, status=status.HTTP_404_NOT_FOUND)

    serializer = ProjectSerializer(project, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(["PUT"])
@permission_classes([IsAuthenticated])
def update_scan_result(request, scan_id, audit_id):
    try:
        new_status = request.data.get("status", "").strip().upper()
        if not new_status:
            return Response({"error": "Status is required."}, status=status.HTTP_400_BAD_REQUEST)

        scan = get_object_or_404(Scan, scan_id=scan_id)

        # 1. Get the current latest version data (which is a list of dicts from JSONField)
        if not scan.scan_result or scan.scan_result_version == 0:
            return Response({"error": "No scan results available to update."}, status=status.HTTP_404_NOT_FOUND)

        latest_version_key = f'v{scan.scan_result_version}'
        parsed_result_current_version = scan.scan_result.get(latest_version_key)

        # Ensure the retrieved data is a list; handle old CSV string format if encountered
        if not isinstance(parsed_result_current_version, list):
            if isinstance(parsed_result_current_version, str):
                try:
                    csv_file = StringIO(parsed_result_current_version)
                    reader = csv.DictReader(csv_file)
                    parsed_result_current_version = list(reader)
                    print(f"[DEBUG] Converted old CSV string from DB for version {latest_version_key}")
                except Exception as e:
                    print(f"\n🔥 Internal Server Error (Parsing old CSV in PUT): {e}")
                    traceback.print_exc()
                    return Response({"error": "Failed to parse existing scan result CSV for update."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            else:
                print(f"\n🔥 Internal Server Error (Unexpected type in PUT): {type(parsed_result_current_version)}")
                return Response({"error": f"Unexpected format for current scan result in version {latest_version_key}."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        # Now, `parsed_result_current_version` is guaranteed to be a list of dictionaries.
        updated_in_memory = False
        for entry in parsed_result_current_version:
            # Check for "CIS.NO" (from CSV) OR "name" (from new JSON format)
            identifier = entry.get("CIS.NO") or entry.get("name")
            if str(identifier) == str(audit_id):
                entry["Status"] = new_status # Update the status in the in-memory list
                updated_in_memory = True
                break

        if not updated_in_memory:
            return Response({"error": "Audit ID not found in the current scan result version."}, status=status.HTTP_404_NOT_FOUND)

        # 2. Update the JSONField in the model for the *same* version key
        # We are modifying the content of the existing latest version in place.
        scan.scan_result[latest_version_key] = parsed_result_current_version
        
        # Save the scan instance. No version increment as we are updating in place.
        scan.save(update_fields=['scan_result']) # Only save the scan_result JSONField
        print(f"[DEBUG] Scan {scan_id} - Version {latest_version_key} updated in DB.")

        # 3. Update the corresponding Excel and CSV files on disk to reflect the change
        # `sync_excel_with_db_csv` now receives the *parsed list of dicts* directly
        updated_excel_path = sync_excel_with_db_csv(scan, parsed_result_current_version)
        
        return Response({
            "message": "Audit status updated successfully.",
            "excel_updated_path": updated_excel_path,
            # Optionally, you might want to return the updated item or whole scan:
            # "updated_item": entry 
        })

    except Exception as e:
        print("\n🔥 Internal Server Error in update_scan_result:")
        traceback.print_exc()
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def update_excel_status(scan, audit_id: str, new_status: str) -> str:
    """
    Updates the Excel file entry matching audit_id with the new status.
    Returns the updated file path or raises errors if fails.
    """

    project_name = scan.project.project_name
    scan_name = scan.scan_name

    compliance_name = scan.scan_data.get("complianceCategory", "").strip().lower().replace(" ", "")
    compliance_category = scan.scan_data.get("complianceSecurityStandard", "").strip().lower()

    # Build relative to current file (views.py)
    base_dir = Path(__file__).resolve().parent.parent  # This gives you backend/DSEC/
    excel_file_path = base_dir / "startScan" / "Projects" / project_name / scan_name / f"{compliance_name}_{compliance_category}_{project_name}_{scan_name}.xlsx"

    if not excel_file_path.exists():
        raise FileNotFoundError(f"Excel file not found: {excel_file_path}")

    # Load workbook
    wb = openpyxl.load_workbook(excel_file_path)
    ws = wb.active

    headers = [cell.value for cell in ws[1]]
    if "CIS.NO" not in headers or "Status" not in headers:
        raise ValueError("Missing 'CIS.NO' or 'Status' in Excel headers.")

    cis_index = headers.index("CIS.NO")
    status_index = headers.index("Status")

    found = False
    for row in ws.iter_rows(min_row=2):
        if str(row[cis_index].value).strip() == str(audit_id):
            row[status_index].value = new_status
            found = True
            break

    if not found:
        raise ValueError("Audit ID not found in Excel file.")

    wb.save(excel_file_path)

    return str(excel_file_path)


def sync_excel_with_db_csv(scan: Scan, parsed_scan_data: list[dict]) -> str:
    """
    Synchronizes the Excel file and its corresponding CSV on disk
    with the provided parsed scan data (list of dicts) for a specific scan version.
    Returns the Excel file path.
    """
    project_name = scan.project.project_name
    scan_name = scan.scan_name

    # Determine filename with version for both CSV and Excel
    # The version number comes from scan.scan_result_version (the latest version in DB)
    version_num = scan.scan_result_version
    
    compliance_name = scan.scan_data.get("complianceCategory", "").strip().lower().replace(" ", "")
    compliance_standard = scan.scan_data.get("complianceSecurityStandard", "").strip().lower()

    # Construct file paths
    base_dir = Path(__file__).resolve().parent.parent 
    project_dir = base_dir / "startScan" / "Projects" / project_name / scan_name

    csv_file_name = f"{compliance_name}_{compliance_standard}_{project_name}_{scan_name}_v{version_num}.csv"
    excel_file_name = f"{compliance_name}_{compliance_standard}_{project_name}_{scan_name}_v{version_num}.xlsx"

    csv_file_path = project_dir / csv_file_name
    excel_file_path = project_dir / excel_file_name

    # ✅ Ensure folder exists
    project_dir.mkdir(parents=True, exist_ok=True)

    # Convert the parsed_scan_data (list of dicts) back to CSV string
    if not parsed_scan_data: # Handle empty data case
        csv_text_to_write = ""
        fieldnames = ["CIS.NO", "Subject", "Description", "Current Settings", "Status", "Remediation"] # Default headers
    else:
        # Assuming all dicts in the list have the same keys, take from the first one
        fieldnames = list(parsed_scan_data[0].keys())
        output_csv = StringIO()
        writer = csv.DictWriter(output_csv, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(parsed_scan_data)
        csv_text_to_write = output_csv.getvalue()

    # ✅ Write the generated CSV string to the .csv file on disk
    with open(csv_file_path, "w", encoding="utf-8") as f:
        f.write(csv_text_to_write)
    print(f"[DEBUG] CSV file updated on disk: {csv_file_path}")

    # ✅ Rebuild (or update) the Excel file from the CSV file
    # This ensures consistency between CSV and Excel.
    convert_csv_to_excel(str(csv_file_path), str(excel_file_path)) # Uses the helper `convert_csv_to_excel`

    return str(excel_file_path) # Return path to the updated Excel


# --- update_excel_status (DEPRECATED or REMOVED/REFACTORED) ---
# This function is no longer needed as a standalone entry point.
# Its functionality is now integrated into `sync_excel_with_db_csv`.
# If you still have calls to this, you should replace them with calls to sync_excel_with_db_csv.
# For clarity, you should remove this function from your views.py entirely if it's unused.

@csrf_exempt
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_scan_output(request, scan_id):
    scan = get_object_or_404(Scan, scan_id=scan_id)
    project = scan.project

    uploaded_file = request.FILES.get("file")
    if not uploaded_file:
        return JsonResponse({"error": "No file uploaded."}, status=400)

    base_dir = Path(__file__).resolve().parent.parent
    target_dir = base_dir / 'startScan' / 'Projects' / project.project_name / scan.scan_name
    os.makedirs(target_dir, exist_ok=True)

    file_path = target_dir / uploaded_file.name
    with open(file_path, 'wb+') as destination:
        for chunk in uploaded_file.chunks():
            destination.write(chunk)

    if file_path.stat().st_size == 0:
        return JsonResponse({"error": "Uploaded file is empty."}, status=400)

    try:
        scan_data = scan.scan_data or {}
        flavour = scan_data.get('flavour', '')
        compliance_standard = scan_data.get('complianceSecurityStandard', '')

        safe_flavour = sanitize(flavour)
        safe_standard = sanitize(compliance_standard)
        safe_project_name = sanitize(project.project_name)
        safe_scan_name = sanitize(scan.scan_name)

        dynamic_filename = f"{safe_flavour}_{safe_standard}_{safe_project_name}_{safe_scan_name}.csv"
        output_report_path = target_dir / dynamic_filename

        if safe_flavour == 'oracle':
            csv_file_path = base_dir / 'startScan' / 'Configuration_Audit' / 'Database' / 'ORACLE' / 'CIS' / 'Validators' / 'check.csv'
            if not csv_file_path.exists():
                return JsonResponse({"error": f"CSV file not found at: {csv_file_path}"}, status=400)

            expected_dict = oraclevalidator.load_csv(csv_file_path)
            oraclevalidator.validate(file_path, expected_dict, output_report_path)

        else:
            return JsonResponse({"error": f"Validation for flavour '{flavour}' is not implemented."}, status=400)

        # ✅ Save raw CSV text into scan_result
        with open(output_report_path, 'r', encoding='utf-8',errors="replace") as f:
            scan.scan_result = f.read()
        scan.save()

    except Exception as e:
        traceback.print_exc()
        return JsonResponse({"error": f"Validation failed: {str(e)}"}, status=500)

    return JsonResponse({
        "message": "File uploaded, validated, and scan_result saved as text.",
        "uploaded_file": str(file_path),
        "validation_report_csv": str(output_report_path),
        "validation_report_xlsx": str(output_report_path.with_suffix('.xlsx'))
    }, status=200)




@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def create_scan(request):
    print("entered create scan")
    request_data = request.data.copy()
    print(request_data)

    project_name = request_data.get("project_name")
    scan_author = request_data.get("scan_author", "unknown")
    scan_name = request_data.get("scan_name")

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

    scan_instance = None
    is_new_scan = False

    existing_scan_query = Scan.objects.filter(scan_name=scan_name, project=project, trash=False)

    if existing_scan_query.exists():
        scan_instance = existing_scan_query.first()
        print(f"Scan with name '{scan_name}' found. Preparing to execute and add a new result version.")
    else:
        is_new_scan = True
        request_data["scan_id"] = str(uuid.uuid4())
        request_data["project"] = project.pk
        print(f"Creating new scan with ID: {request_data['scan_id']} (initial version v1 expected).")

        serializer = ScanSerializer(data=request_data)
        if serializer.is_valid():
            scan_instance = serializer.save() # Saves with scan_result_version=0 initially
        else:
            print("[!] Serializer Errors for new scan creation:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    if scan_instance is None:
        return Response({"error": "Failed to create or retrieve scan instance."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    scan_data_for_execution = request_data.get("scan_data", {})
    
    file_path = None
    output_json_path = None
    try:
        result = launch_scan(request_data) 
        if result is None:
            print("[!] launch_scan() returned None")
            scan_instance.scan_status = "failed"
            scan_instance.save()
            return Response({"error": "Scan execution failed"}, status=500)

        file_path, output_json_path = result
        print("[DEBUG] Returned file_path:", file_path)
        print("[DEBUG] file exists:", os.path.exists(file_path))
    except Exception as e:
        print("[!] launch_scan() failed:", e)
        scan_instance.scan_status = "failed"
        scan_instance.save()
        return Response({"error": "Scan execution failed", "details": str(e)}, status=500)

    if output_json_path and os.path.exists(output_json_path):
        with open(output_json_path, "r", encoding="utf-8") as f:
            try:
                output_data = json.load(f)
                scan_instance.scan_output = output_data
            except json.JSONDecodeError:
                print("[!] Failed to decode output.json")

    scan_result_content_to_store = None
    response_file = None 

    if file_path and os.path.exists(file_path):
        audit_method = scan_data_for_execution.get("auditMethod", "").strip().lower()
        category = scan_data_for_execution.get("category", "").strip().lower()

        filename = os.path.basename(file_path)
        
        if filename.lower().endswith('.csv'):
            print("Processing scan result (CSV).")
            with open(file_path, "r", encoding="utf-8", errors="replace") as f:
                csv_text = f.read()
            
            try:
                csv_file = StringIO(csv_text)
                reader = csv.DictReader(csv_file)
                scan_result_content_to_store = list(reader)
            except Exception as e:
                print(f"[!] Failed to parse CSV from {file_path}: {e}")
                scan_instance.scan_status = "failed_csv_parse"
                scan_instance.save()
                return Response({"error": "Failed to parse scan result as CSV."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

            # --- CRITICAL FIX START ---
            scan_instance.update_scan_result(scan_result_content_to_store) 
            # update_scan_result internally calls scan_instance.save()
            # After this, scan_instance's Python object is NOT automatically refreshed with DB values.
            # We need to re-fetch it to get the latest scan_result_version and scan_result JSONField content.
            
            # Re-fetch the scan_instance to get its most updated state from DB
            scan_instance = Scan.objects.get(pk=scan_instance.pk) # Refresh from DB
            print(f"[DEBUG_VIEW] Refreshed scan_instance. New version: {scan_instance.scan_result_version}")
            # --- CRITICAL FIX END ---

            response_file = FileResponse(BytesIO(csv_text.encode("utf-8")), content_type="text/csv")
            response_file['Content-Disposition'] = f'attachment; filename="{filename}"'

        elif audit_method == "agent" and category == "linux":
            print("Processing agent script file.")
            filename = f"{scan_data_for_execution.get('complianceCategory', '').strip().replace(' ', '_')}_audit_script.sh"
            mime_type, _ = mimetypes.guess_type(file_path)
            mime_type = mime_type or "application/octet-stream"
            response_file = FileResponse(
                open(file_path, "rb"),
                as_attachment=True,
                filename=filename,
                content_type=mime_type
            )
        else:
            print(f"[!] Unknown file type or handling for: {file_path}")
            scan_instance.scan_status = "failed_unknown_file_type"
            scan_instance.save()
            return Response({"error": "Unknown scan result file type."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    else:
        print("[!] No scan_result file generated or found.")
        scan_instance.scan_status = "completed_no_result_file"
        scan_instance.save()


    if scan_result_content_to_store is None:
         scan_instance.scan_status = "complete"
         scan_instance.save()

    # The final serialization must use the refreshed scan_instance
    if response_file:
        return response_file
    else:
        return Response({
            "message": "Scan initiated and processed successfully.",
            "scan": ScanSerializer(scan_instance).data # Use the refreshed scan_instance
        }, status=status.HTTP_201_CREATED if is_new_scan else status.HTTP_200_OK)



import re

def launch_scan(data):
    print("[*] Entered launch_scan()")
    scan_data = data.get("scan_data", {})
    

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
           return database_config_audit(data)
           

        if category=="windows":
            
            return windows_config_audit(data)

        if category == "linux":
            return linux_config_audit(data)

        if category=="firewall":
            return None,None
        
        if category == "firewall":
            return None, None

    elif scan_type == "compromiseassessment":
        if category == "windows":
            return windows_compromise_assesment(data)

    
        if category == "linux":
            return None, None

           
    return None, None  