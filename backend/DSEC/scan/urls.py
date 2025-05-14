from django.contrib import admin
from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from . import views


urlpatterns = [
   # Projects
    path('projects/', views.get_projects_view),
    path('project/<str:project_id>/', views.get_project_by_id,),
    path('all-projects/', views.get_all_projects_view, name='get_all_projects'),
    path('project/create/', views.create_project_view),
    path('project/trash/<str:project_id>/', views.update_project_view),
    path('projects/trash/', views.trashed_projects_view, ),
    path('project/trash/delete/<str:project_id>/', views.delete_project_view),
    path('projects/trash/deleteAll', views.delete_all_projects_view),


    # Scans
    path('scans/', views.get_scans_view),
    path('scans/create/', views.create_scan_view),
    path('scans/update/<int:pk>/', views.update_scan_view),
    path('scans/user/', views.get_user_scans_view, name='get_user_scans'),

    path('scans/upload/', views.post_scan_file),
    path('scans/project/<str:project_id>/', views.get_project_scans_view),
    path('scans/', views.MyProjectsView.as_view(), name='scan-list'),
    path('scans/add/', views.add_MyProjectsView, name='scan-add'),
    path('scans/<str:scan_id>/trash/', views.update_MyProjectsView, name='move_to_trash'),
    path('scans/trashed/', views.trashed_scans_view, name='trashed_scans'),
    path('scans/compliance/configaudit/<str:os_name>/', views.get_compliance_data, name='compliance-data'),
    path('scans/compliance/ioc/<str:os_name>/', views.get_compromise_assessment_data, name='compromise-assessment-data'),
   

]



