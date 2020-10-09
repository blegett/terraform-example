import json
import boto3

# boto3 S3 initialization
s3 = boto3.resource("s3")

# boto4 DynamoDB initialization
dynamodb = boto3.client("dynamodb")

def lambda_handler(event, context):

    # event contains all information about uploaded object
    print("Event :", event)

    # Name of the source bucket
    source_bucket_name = event['Records'][0]['s3']['bucket']['name']

    # Filename of object (with path)
    file_key_name = event['Records'][0]['s3']['object']['key']

    # Grab the object located in s3, and read the body of json file
    obj = s3.Object(source_bucket_name, file_key_name)
    string = obj.get()['Body'].read().decode('utf-8')

    # loads data into a json file
    record = json.loads(string)

    # assign records to variables
    tableId = record['id']
    crashDetected = record['crashDetected']
    speed = record['speed']

    # insert into dynamodb table
    dynamodb.put_item(
        TableName='testing-table',
        Item={

            'id': {
                "S": tableId
            },
            'crashDetected': {
                "S": crashDetected
            },
            'speed': {
                "S": speed
            }
        }

    )
