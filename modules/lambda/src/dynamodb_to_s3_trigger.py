import boto3
import json
import os

s3 = boto3.client("s3")
bucket = os.environ["S3_BUCKET"]

def lambda_handler(event, context):
    for record in event.get("Records", []):
        if record.get("eventName") == "INSERT":
            new_image = record.get("dynamodb", {}).get("NewImage", {})
            if not new_image:
                continue

            # Explicit ordering
            ordered_keys = ["id", "name", "email", "timestamp"]
            item = {k: list(new_image[k].values())[0] for k in ordered_keys if k in new_image}

            key = f"{item.get('id', 'unknown')}.json"
            s3.put_object(
                Bucket=bucket,
                Key=f"data/{key}",
                Body=json.dumps(item)
            )

    return {"statusCode": 200}
