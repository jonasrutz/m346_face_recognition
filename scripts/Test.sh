#!/bin/bash
# Author: Alexej
# Datum: 17.03.2026
# Beschreibung: Dieses Skript testet den AWS Face Recognition Service, indem es ein Bild in den In-Bucket hochlädt und die Ergebnisse aus dem Out-Bucket abruft.
# Quellen:
# - https://docs.aws.amazon.com/cli/latest/reference/s3/cp.html
# - https://docs.python.org/3/library/json.html


set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: bash Test.sh <path-to-image.jpg>"
    echo "Example: bash Test.sh myfoto.jpg"
    exit 1
fi

IMAGE_PATH=$1
IMAGE_NAME=$(basename "$IMAGE_PATH")
IMAGE_BASE="${IMAGE_NAME%.*}"
JSON_NAME="${IMAGE_BASE}.json"

echo "=========================================="
echo " AWS Face Recognition Test"
echo "=========================================="
echo "Image: $IMAGE_PATH"

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
IN_BUCKET="face-rekog-in-${ACCOUNT_ID}"
OUT_BUCKET="face-rekog-out-${ACCOUNT_ID}"

echo "[+] Uploading $IMAGE_NAME to In-Bucket ($IN_BUCKET)..."
# Upload test image to trigger S3->Lambda event chain.
aws s3 cp "$IMAGE_PATH" "s3://${IN_BUCKET}/${IMAGE_NAME}" >/dev/null

echo "[+] Waiting for Lambda Face Recognition..."
sleep 8

echo "[+] Fetching results from Out-Bucket ($OUT_BUCKET)..."
# Download generated JSON and print key fields in a human-readable form.
if aws s3 cp "s3://${OUT_BUCKET}/${JSON_NAME}" "/tmp/${JSON_NAME}" >/dev/null 2>&1; then
    echo "[+] Results downloaded successfully to /tmp/${JSON_NAME}"
    
    echo "=========================================="
    echo " Rekognition Result:"
    echo "=========================================="
    
    PYTHON_CMD="python3"
    if ! command -v python3 &> /dev/null; then
        PYTHON_CMD="python"
    fi
    $PYTHON_CMD -c "
import json, sys
try:
    with open('/tmp/${JSON_NAME}', 'r') as f:
        data = json.load(f)
        celebrities = data.get('CelebrityFaces', [])
        if not celebrities:
            print('No known celebrities detected with high enough confidence.')
        for p in celebrities:
            name = p.get('Name', 'Unknown')
            confidence = p.get('MatchConfidence', 0)
            print(f'- {name} (Confidence: {confidence:.2f}%)')
            
        unrecognized = data.get('UnrecognizedFaces', [])
        if unrecognized:
            print(f'Also detected {len(unrecognized)} unrecognized face(s).')
except Exception as e:
    print('Error parsing JSON:', e)
"
    
    rm "/tmp/${JSON_NAME}"
else
    echo "[-] Error: Result file ${JSON_NAME} not found in Out-Bucket."
    echo "    Check CloudWatch Logs for the Lambda function for potential errors."
    exit 1
fi

echo "=========================================="
echo " Test Complete!"
echo "=========================================="
