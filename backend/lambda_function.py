from datetime import datetime, timezone
import json
import uuid
import boto3


table = boto3.resource("dynamodb").Table("bfl-incidents")

def lambda_handler(event, context):
    method = event["requestContext"]["http"]["method"]

    if method == "GET":
        items = table.scan()["Items"]
        items.sort(key=lambda i: i.get("created_at", ""))
        return {"statusCode": 200, "body": json.dumps(items)}

    if method == "POST":
        data = json.loads(event.get("body") or "{}")
        title = data.get("title", "").strip()

        if not title:
            return {"statusCode": 400, "body": json.dumps({"error": "title is required"})}
        if len(title) > 100:
            return {"statusCode": 400, "body": json.dumps({"error": "title is too long (max 100)"})}

        item = {
            "id": str(uuid.uuid4()),
            "title": title,
            "symptom": data.get("symptom", "")[:500],
            "root_cause": data.get("root_cause", "")[:500],
            "fix": data.get("fix", "")[:500],
            "status": "open",
            "created_at": datetime.now(timezone.utc).isoformat()
        }
        table.put_item(Item=item)
        return {"statusCode": 201, "body": json.dumps(item)}