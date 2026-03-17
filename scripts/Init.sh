#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
IN_BUCKET="face-rekog-in-${ACCOUNT_ID}"
OUT_BUCKET="face-rekog-out-${ACCOUNT_ID}"
LAMBDA_NAME="FaceRekognitionFunction"

echo "=========================================="
echo " AWS Face Recognition Service Setup"
echo "=========================================="
echo "Region:     $REGION"
echo "Account ID: $ACCOUNT_ID"
echo "In-Bucket:  $IN_BUCKET"
echo "Out-Bucket: $OUT_BUCKET"
echo "Lambda:     $LAMBDA_NAME"
echo "=========================================="

echo "[+] Constructing LabRole ARN..."
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/LabRole"
echo "    LabRole ARN: $ROLE_ARN"

echo "[+] Creating S3 Buckets..."
if ! aws s3api head-bucket --bucket "$IN_BUCKET" 2>/dev/null; then
    aws s3api create-bucket --bucket "$IN_BUCKET" --region "$REGION" >/dev/null
    echo "    Created In-Bucket: $IN_BUCKET"
else
    echo "    In-Bucket already exists: $IN_BUCKET"
fi

if ! aws s3api head-bucket --bucket "$OUT_BUCKET" 2>/dev/null; then
    aws s3api create-bucket --bucket "$OUT_BUCKET" --region "$REGION" >/dev/null
    echo "    Created Out-Bucket: $OUT_BUCKET"
else
    echo "    Out-Bucket already exists: $OUT_BUCKET"
fi

echo "[+] Packaging Lambda function..."
cd ../src
if command -v zip &> /dev/null; then
    zip -rq lambda_function.zip lambda_function.py
else
    python3 -c "import zipfile; z = zipfile.ZipFile('lambda_function.zip', 'w'); z.write('lambda_function.py'); z.close()" 2>/dev/null || python -c "import zipfile; z = zipfile.ZipFile('lambda_function.zip', 'w'); z.write('lambda_function.py'); z.close()"
fi
cd ../scripts

echo "[+] Deploying Lambda function..."
if aws lambda get-function --function-name "$LAMBDA_NAME" >/dev/null 2>&1; then
    echo "    Updating existing Lambda function code..."
    aws lambda update-function-code \
        --function-name "$LAMBDA_NAME" \
        --zip-file fileb://../src/lambda_function.zip >/dev/null
    aws lambda update-function-configuration \
        --function-name "$LAMBDA_NAME" \
        --environment "Variables={OUT_BUCKET=$OUT_BUCKET}" >/dev/null
else
    echo "    Creating new Lambda function..."
    aws lambda create-function \
        --function-name "$LAMBDA_NAME" \
        --runtime python3.11 \
        --role "$ROLE_ARN" \
        --handler lambda_function.lambda_handler \
        --environment "Variables={OUT_BUCKET=$OUT_BUCKET}" \
        --timeout 30 \
        --zip-file fileb://../src/lambda_function.zip >/dev/null
fi

echo "    Waiting for Lambda function to be active..."
aws lambda wait function-active-v2 --function-name "$LAMBDA_NAME"

echo "[+] Configuring Lambda permissions..."
LAMBDA_ARN=$(aws lambda get-function --function-name "$LAMBDA_NAME" --query 'Configuration.FunctionArn' --output text)

aws lambda remove-permission --function-name "$LAMBDA_NAME" --statement-id s3invoke 2>/dev/null || true

aws lambda add-permission \
    --function-name "$LAMBDA_NAME" \
    --principal s3.amazonaws.com \
    --statement-id s3invoke \
    --action "lambda:InvokeFunction" \
    --source-arn "arn:aws:s3:::$IN_BUCKET" \
    --source-account "$ACCOUNT_ID" >/dev/null

echo "[+] Configuring S3 Event Notification..."
cat <<EOF > /tmp/s3-notification.json
{
  "LambdaFunctionConfigurations": [
    {
      "LambdaFunctionArn": "$LAMBDA_ARN",
      "Events": ["s3:ObjectCreated:*"]
    }
  ]
}
EOF

aws s3api put-bucket-notification-configuration \
    --bucket "$IN_BUCKET" \
    --notification-configuration file:///tmp/s3-notification.json

rm /tmp/s3-notification.json
rm ../src/lambda_function.zip

echo "=========================================="
echo " Setup Complete!"
echo " The Face Recognition Service is ready."
echo " You can test it by uploading an image into $IN_BUCKET"
echo " or by running: bash Test.sh <path-to-image.jpg>"
echo "=========================================="
