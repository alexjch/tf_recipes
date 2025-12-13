import os
import json
import boto3
import uuid
import time
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')


def save_message(bucket_name, key, message):
    try:
        # Save to S3
        s3_client.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=json.dumps(message),
            ContentType='application/json'
        )
    except Exception as e:
        logger.error(f"Failed to upload receipt to S3: {str(e)}")
        raise


def handler(event, context):

    try:
        # Get bucket name from environment variable
        bucket_name = os.environ.get("S3_BUCKET", None)
        if not bucket_name:
            raise ValueError("Missing required environment variable S3_BUCKET")

        # Generate a unique key with timestamp
        timestamp = int(time.time())
        date_dir = time.strftime('%Y%m%d', time.gmtime(timestamp))
        key = f"{date_dir}/{timestamp}-{uuid.uuid4()}"
    
        save_message(bucket_name, key, event)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Data saved successfully',
                'filename': key,
            })
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error saving data',
                'error': str(e)
            })
        }
