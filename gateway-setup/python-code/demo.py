import json

def lambda_handler(event, context):
    # TODO implement
    if(event["queryStringParameters"]):
        print("passed")
        return {
        'statusCode': 200,
        'body': json.dumps('Passed')
    }
    else:
        return {
                'statusCode': 200,
                'body': json.dumps('Not passed')
                }
