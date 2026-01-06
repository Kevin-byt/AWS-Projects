#!/bin/bash

echo "🔍 Validating Terraform configuration..."

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed"
    exit 1
fi

# Initialize terraform
echo "📦 Initializing Terraform..."
terraform init

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

if [ $? -eq 0 ]; then
    echo "✅ Terraform configuration is valid!"
else
    echo "❌ Terraform configuration has errors"
    exit 1
fi

# Format check
echo "🎨 Checking Terraform formatting..."
terraform fmt -check

if [ $? -eq 0 ]; then
    echo "✅ Terraform files are properly formatted!"
else
    echo "⚠️  Some files need formatting. Run 'terraform fmt' to fix."
fi

# Plan (dry run)
echo "📋 Running Terraform plan..."
terraform plan

echo "🎉 Validation complete!"