from main.views import api_root
from django.contrib import admin
from django.urls import path, include


urlpatterns = [
    path('', api_root),
    path('admin/', admin.site.urls),
    path('api-auth/', include('rest_framework.urls')),
    path('', include('users.urls')),
    path('', include('books.urls')),
    path('', include('shelves.urls')),
    path('', include('topics.urls')),
]
