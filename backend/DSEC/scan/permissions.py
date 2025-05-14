from rest_framework.permissions import BasePermission

class IsAdminUserCustom(BasePermission):
    def has_permission(self, request, view):
        # Check if user is authenticated and has 'is_admin' in token
        return request.user and request.user.is_authenticated and request.auth.get('is_admin', False)
