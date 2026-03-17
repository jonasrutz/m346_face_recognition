import json
import boto3
import os
import urllib.parse

print('Loading function')

s3 = boto3.client('s3')
rekognition = boto3.client('rekognition')

def lambda_handler(event, context):
    try:
        out_bucket = os.environ.get('OUT_BUCKET')
        if not out_bucket:
            raise ValueError("Environment variable OUT_BUCKET is not set.")

        bucket = event['Records'][0]['s3']['bucket']['name']
        key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
        print(f"Processing image {key} from bucket {bucket}")

        response = rekognition.recognize_celebrities(
            Image={
                'S3Object': {
                    'Bucket': bucket,
                    'Name': key
                }
            }
        )
        
        file_name, _ = os.path.splitext(key)
        out_key = f"{file_name}.json"
        
        s3.put_object(
            Bucket=out_bucket,
            Key=out_key,
            Body=json.dumps(response, indent=2),
            ContentType='application/json'
        )
        print(f"Successfully processed and saved results to {out_bucket}/{out_key}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Face recognition completed successfully!')
        }
    except Exception as e:
        print(f"Error processing object. Error message: {e}")
        print('Make sure the bucket exists and your bucket is in the same region as this function.')
        raise e
