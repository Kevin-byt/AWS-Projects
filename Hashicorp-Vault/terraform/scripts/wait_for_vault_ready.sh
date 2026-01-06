#!/bin/bash
set -e

VAULT_IP="$1"
AWS_REGION="$2"
MAX_ATTEMPTS=60
ATTEMPT=0

echo "Waiting for Vault to be ready at $VAULT_IP..."

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    # Check if Vault is responding
    if curl -s -f "http://$VAULT_IP:8200/v1/sys/health" > /dev/null 2>&1; then
        echo "Vault is responding (attempt $ATTEMPT)"
        
        # Check if root token is available in SSM
        if aws ssm get-parameter --name "/vault/root_token" --with-decryption --region "$AWS_REGION" > /dev/null 2>&1; then
            echo "Root token found in SSM Parameter Store"
            
            # Verify Vault is unsealed
            HEALTH_STATUS=$(curl -s "http://$VAULT_IP:8200/v1/sys/health" | jq -r '.sealed // true')
            if [ "$HEALTH_STATUS" = "false" ]; then
                echo "Vault is ready and unsealed"
                exit 0
            else
                echo "Vault is sealed, waiting..."
            fi
        else
            echo "Root token not yet available in SSM, waiting..."
        fi
    else
        echo "Vault not responding yet (attempt $ATTEMPT)"
    fi
    
    sleep 10
done

echo "ERROR: Vault did not become ready within $((MAX_ATTEMPTS * 10)) seconds"
exit 1