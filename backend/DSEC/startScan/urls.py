from django.contrib import admin
from django.urls import path,re_path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from . import views

urlpatterns = [
    # Match dynamic folder paths like configurationaudit/database/oracle
   re_path(r'^get-csv/(?P<folder_path>[\w/-]+)/(?P<filename>[\w.-]+)/$', views.get_csv_file),
   path('download/project/<str:project_name>/', views.download_project_excels, name='download_project_excels'),
   path('download/project/<str:project_name>/scan/<str:scan_name>/', views.download_project_scan_excels),
]