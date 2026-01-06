from django.urls import path
from . import views

urlpatterns = [
    path('', views.getBooks, name='api-root'),
    path('health/', views.health_check, name='health'),
    path('books/', views.getBooks, name='get-books'),
    path('books/<int:pk>/', views.getBook, name='get-book'),

]