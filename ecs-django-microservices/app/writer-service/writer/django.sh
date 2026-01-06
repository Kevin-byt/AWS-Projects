#!/bin/bash

echo "create migrations"
python manage.py makemigrations writer
echo "==================================="

echo "migrate"
python manage.py migrate
echo "==================================="

echo "start server"
python manage.py runserver 0.0.0.0:8000