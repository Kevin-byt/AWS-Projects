#!/bin/bash

# Create package directory
mkdir -p package

# Install dependencies
pip install -r requirements.txt -t package/

# Copy lambda function
cp lambda_function.py package/

# Create zip file
cd package
zip -r ../lambda_function.zip .
cd ..

# Clean up
rm -rf package

echo "Lambda package created: lambda_function.zip"