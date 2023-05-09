from topics.views import TopicViewSet
from django.urls import path, include
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'topics', TopicViewSet, basename='topic')

urlpatterns = [
    path('', include(router.urls))
]
