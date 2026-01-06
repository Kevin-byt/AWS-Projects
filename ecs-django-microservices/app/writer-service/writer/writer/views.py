# The app's controllers

from django.shortcuts import render
from django.http import JsonResponse
from rest_framework.response import Response
from rest_framework.decorators import api_view

from .models import Library
from .serializers import LibrarySerializer

# Health check endpoint
def health_check(request):
    return JsonResponse({'status': 'healthy', 'service': 'writer'})

# Root endpoint - handles both GET and POST
@api_view(['GET', 'POST'])
def api_root(request):
    if request.method == 'GET':
        return Response({
            'message': 'Writer Service API',
            'endpoints': {
                'POST /': 'Create a book',
                'POST /books/create/': 'Create a book',
                'PUT /books/{id}/update/': 'Update a book',
                'GET /health/': 'Health check'
            },
            'example': {
                'title': 'Book Title',
                'author': 'Author Name', 
                'description': 'Book Description'
            }
        })
    
    # POST request - create book
    serializer = LibrarySerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=201)
    return Response(serializer.errors, status=400)

#create a book
@api_view(['POST'])
def createBook(request):
    serializer = LibrarySerializer(data=request.data)

    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=201)

    print("Errors:", serializer.errors)
    return Response(serializer.errors, status=400)

#update a book
@api_view(['PUT'])
def updateBook(request, pk):
    try:
        book = Library.objects.get(id=pk)
    except Library.DoesNotExist:
        return Response(status=404)

    serializer = LibrarySerializer(instance=book, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=400)

#delete a Book
@api_view(['DELETE'])
def deleteBook(request, pk):
    book = Library.objects.get(id=pk)
    book.delete()
    return Response('Book was deleted')