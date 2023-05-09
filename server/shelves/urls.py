from django.urls import path, include
from shelves.views import ShelfViewSet
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'shelves', ShelfViewSet, basename='shelf')

urlpatterns = [
    path('', include(router.urls))
]
