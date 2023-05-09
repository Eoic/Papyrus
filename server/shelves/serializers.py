from shelves.models import Shelf
from rest_framework import serializers


class ShelfSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Shelf
        fields = ['title', 'description', 'owner']