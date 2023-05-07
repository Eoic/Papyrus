from books.models import Book
from books.serializers import BookSerializer
from rest_framework.viewsets import ModelViewSet
from rest_framework.permissions import DjangoModelPermissionsOrAnonReadOnly


class BookViewSet(ModelViewSet):
    queryset = Book.objects.all()
    serializer_class = BookSerializer
    permission_classes = [DjangoModelPermissionsOrAnonReadOnly]

    def perform_create(self, serializer):
        return serializer.save(owner=self.request.user)
