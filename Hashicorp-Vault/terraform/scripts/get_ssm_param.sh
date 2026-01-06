#!/bin/bash
set -e
# Arguments: name region
NAME="$1"
REGION="$2"
MAX_ATTEMPTS=10
ATTEMPT=0

if [ -z "$NAME" ]; then
  echo '{"value":""}'
  exit 0
fi

if [ -z "$REGION" ]; then
  REGION="us-east-1"
fi

# Retry logic for SSM parameter retrieval
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    OUTPUT=$(aws ssm get-parameter --name "$NAME" --with-decryption --region "$REGION" 2>/dev/null || true)
    
    if [ -n "$OUTPUT" ]; then
        # Extract the value using jq
        VALUE=$(echo "$OUTPUT" | jq -r '.Parameter.Value' 2>/dev/null || true)
        if [ -n "$VALUE" ] && [ "$VALUE" != "null" ]; then
            # Escape the value for JSON
            printf '{"value":"%s"}' "$(echo "$VALUE" | sed 's/"/\\"/g')"
            exit 0
        fi
    fi
    
    echo "Attempt $ATTEMPT: Parameter not found, waiting..." >&2
    sleep 5
done

# Return empty value after all attempts
echo '{"value":""}'
exit 0
