from django.contrib import admin
from django.urls import path, include
from users.urls import router as users_router
from books.urls import router as books_router

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api-auth/', include('rest_framework.urls')),
    path('', include('users.urls')),
    path('', include('books.urls')),
]
