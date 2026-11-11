import json
import boto3

table = boto3.resource("dynamodb").Table("bfl-incidents")

def lambda_handler(event, context):
    items = table.scan()["Items"]
    return {
        "statusCode": 200,
        "body": json.dumps(items)
    }