from django.contrib import admin
from django.urls import path,re_path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from . import views

urlpatterns = [
    # Match dynamic folder paths like configurationaudit/database/oracle
    re_path(r'^get-json/(?P<folder_path>[\w/-]+)/(?P<filename>[\w.-]+)/$', views.get_json_file),
]