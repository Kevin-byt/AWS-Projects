from django.urls import path
from . import views

urlpatterns = [
    path('', views.health_check, name='health-check'),
    path('health/', views.health_check, name='health'),
    path('books/create/', views.createBook, name='create-book'),
    path('books/<int:pk>/update/', views.updateBook, name='update-book'),
    path('books/<int:pk>/delete/', views.deleteBook, name='delete-book'),
]
