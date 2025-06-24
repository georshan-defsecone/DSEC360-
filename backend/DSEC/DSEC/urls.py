from django.contrib import admin
from django.urls import path, include
from user.views import MyTokenObtainPairView
from user.serializers import MyTokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenRefreshView
from rest_framework_simplejwt.views import TokenVerifyView


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/token/', MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    path('api/', include('scan.urls')),
    path('api/', include('user.urls')),
    path('api/', include('startScan.urls')),

    
]
