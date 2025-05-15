import requests
import os
import base64

def handler(event, context):

    if event["requestContext"]["http"]["method"] != "POST":
        print("Method Not Allowed")
        return {
            "statusCode": 405
        }

    headers = event["headers"]
    body = event["body"]
    if event["isBase64Encoded"]:
        body = base64.b64decode(event["body"])

    # Dont make the service aware of the repeater
    del headers["host"]

    print("Forwarding request to: ", os.environ["WEBHOOK_ENDPOINT"])
    print("Forwarding headers: ", headers)
    print("Forwarding body: ", body)

    print("Forwarding request...")
    response = requests.post(os.environ["WEBHOOK_ENDPOINT"], headers=headers, data=body)

    # Convert from CaseInsensitiveDict to dict
    response_headers = dict(**response.headers)

    print("Response Status: ", response.status_code)
    print("Response Headers: ", response_headers)
    print("Response Body: ", response.text)

    return {
        "isBase64Encoded": False,
        "body": response.text,
        "headers": response_headers,
        "statusCode": response.status_code
    }

