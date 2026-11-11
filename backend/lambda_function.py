import json
import uuid
import boto3

table = boto3.resource("dynamodb").Table("bfl-incidents")

def lambda_handler(event, context):
    method = event["requestContext"]["http"]["method"]

    if method == "GET":
        items = table.scan()["Items"]
        return {"statusCode": 200, "body": json.dumps(items)}

    if method == "POST":
        data = json.loads(event["body"])
        item = {
            "id": str(uuid.uuid4()),
            "title": data["title"],
            "status": "open"
        }
        table.put_item(Item=item)
        return {"statusCode": 201, "body": json.dumps(item)}