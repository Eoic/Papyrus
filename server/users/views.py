from django.contrib.auth.models import User
from users.serializers import UserSerializer
from rest_framework.viewsets import ReadOnlyModelViewSet


class UserViewSet(ReadOnlyModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer