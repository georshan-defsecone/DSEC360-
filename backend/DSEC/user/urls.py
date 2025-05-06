from django.contrib import admin
from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from . import views


urlpatterns = [
    path('users/', views.get_all_users, name='get-all-users'),
    path('users/createuser',views.create_user,name='create-user'),
    path('users/userinfo',views.get_authenticated_user,name='userinfo'),
    path('updateuser/', views.update_user,name="updateuser"),
    path('save-proxy-settings/', views.save_proxy_settings,name='saveproxy'),
    path('get-proxy-settings/', views.get_proxy_settings,name="getproxy"),
    path('save-smtp-settings/', views.save_smtp_settings,name='savesmtp'),
    path('get-smtp-settings/', views.get_smtp_settings,name="getproxy"),
    path('save-ldap-settings/', views.save_ldap_settings,name='saveldap'),
    path('get-ldap-settings/', views.get_ldap_settings,name="getldap"),
    path('load-json/', views.load_json_to_db, name='load_json_to_db'),



]