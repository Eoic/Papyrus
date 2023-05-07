from books.models import Book
from rest_framework import serializers


class BookSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Book
        fields = [
            'title',
            'author',
            'isbn',
            'publisher',
            'language',
            'genre',
            'description',
            'cover',
            'pages',
            'format',
            'owner',
            'file_url',
            'published_at',
            'created_at',
            'updated_at'
        ]