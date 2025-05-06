import boto3
import os

databrew = boto3.client('databrew')
job_name = os.environ['DATABREW_JOB_NAME']

def lambda_handler(event, context):
    print(f"Triggered by S3 event: {event}")
    response = databrew.start_job_run(Name=job_name)
    print(f"Started DataBrew job: {response['RunId']}")
    return {"statusCode": 200}
