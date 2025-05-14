from rest_framework import serializers
from .models import User


from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [ 'username', 'email','id','is_admin']

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
    
class RegisterSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'is_admin']
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        user = User(
            username=validated_data['username'],
            email=validated_data['email'],
            is_admin=validated_data.get('is_admin', False)
        )
        user.set_password(validated_data['password'])
        user.save()
        return user
    
class UserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['username', 'email']  # Only allow name and email updates

    def update(self, instance, validated_data):
        # Update the instance fields
        instance.username = validated_data.get('username', instance.username)
        instance.email = validated_data.get('email', instance.email)

        # Save the updated user
        instance.save()
        return instance