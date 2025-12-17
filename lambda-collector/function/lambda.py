import os
import json
import base64
import boto3
import botocore
import uuid
import time
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client("s3")

def _get_secret(secret_name):
    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name="us-west-2")

    try:
        # Retrieve the secret
        response = client.get_secret_value(SecretId=secret_name)
        # Decrypts secret using the associated KMS key.
        return response["SecretString"]
    except botocore.exceptions.ClientError as e:
        logger.exception(f"Secrets manager returned an exception {str(e)}")

    return None

def _parse_json_body(event):
    body = event.get("body", "")
    if not body:
        return None

    # If body is base64 encoded, decode first
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")

    return json.loads(body)


def _save_message(bucket_name, key, body):
    try:
        # Save to S3
        s3_client.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=json.dumps(body),
            ContentType="application/json"
        )
    except botocore.exceptions.ClientError as e:
            logger.exception(f"S3 client error while saving message {str(e)}")
            return str(e)
    except Exception as e:
        logger.exception(f"Unexpected error while saving message {str(e)}")
        return str(e)

    return None


def handler(event, context):

    # Get token from headers
    authorization_header = event.get("headers", {}).get("authorization", "")
    token = ""
    if authorization_header.startswith("Bearer "):
        _, token = authorization_header.split(" ")

    # Is token valid
    if not token:
        return {
            "statusCode": 401,
            "body": json.dumps({
                "message": "Unable to authorize",
                "error": "Authorization token is missing in request"
            })
        }

    # Get secret name
    secret_name = os.environ.get("SECRET_NAME", None)
    if not secret_name:
        logger.error("Missing required environment variable SECRET_NAME")
        return {
            "statusCode": 400,
            "body": json.dumps({
                "message": "SECRET_NAME Configuration error",
                "error": "Secret manager is missconfigured"
            })
        }

    # Get secret
    secret = _get_secret(secret_name)
    if not secret:
        logger.error(f"Unable to find secret: {secret_name}")
        return {
            "statusCode": 401,
            "body": json.dumps({
                "message": "Unable to authorize",
                "error": "Failed loading secret manager"
            })
        }

    # Validate the token
    if token != secret:
        logger.error(f"Invalid token: {token}")
        return {
            "statusCode": 401,
            "body": json.dumps({
                "message": "Unable to authorize",
                "error": "Authorization token is invalid"
            })
        }

    # Get bucket name from environment variable
    bucket_name = os.environ.get("S3_BUCKET", None)
    if not bucket_name:
        logger.error("Missing required environment variable S3_BUCKET")
        return {
            "statusCode": 400,
            "body": json.dumps({
                "message": "S3_BUCKET Configuration error",
                "error": "Backend storage is missconfigured"
            })
        }

    # Generate a unique key with timestamp
    timestamp = int(time.time())
    date_dir = time.strftime("%Y%m%d", time.gmtime(timestamp))
    key = f"{date_dir}/{timestamp}-{uuid.uuid4()}"

    if (body := _parse_json_body(event)) is None:
        return {
            "statusCode": 400,
            "body": json.dumps({
                "message": "Failed to parse request body",
                "error": "Client request does not contain `body` key"
            })
        }

    if (save_error_str := _save_message(bucket_name, key, body)):
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Failed to save message to S3",
                "error": save_error_str,
            })
        }

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Data saved successfully",
            "filename": key,
        })
    }
