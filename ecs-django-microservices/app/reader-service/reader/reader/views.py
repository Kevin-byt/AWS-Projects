# The app's controllers

from django.shortcuts import render
from django.http import JsonResponse
from rest_framework.response import Response
from rest_framework.decorators import api_view

from .models import Library
from .serializers import LibrarySerializer

# Health check endpoint
def health_check(request):
    return JsonResponse({'status': 'healthy', 'service': 'reader'})

#get all books
@api_view(['GET'])
def getBooks(request):
    books = Library.objects.all()
    serializer = LibrarySerializer(books, many=True)
    return Response(serializer.data)

#get a single book
@api_view(['GET'])
def getBook(request, pk):
    book = Library.objects.get(id=pk)
    serializer = LibrarySerializer(book, many=False)
    return Response(serializer.data)

