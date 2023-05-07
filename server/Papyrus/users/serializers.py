from django.contrib.auth.models import User
from rest_framework.serializers import ModelSerializer, HyperlinkedRelatedField


class UserSerializer(ModelSerializer):
    books = HyperlinkedRelatedField(many=True, view_name='book-detail', read_only=True)

    class Meta:
        model = User
        fields = ['url', 'id', 'username', 'books']