import boto3
import argparse

parser = argparse.ArgumentParser(description="Get the Physical ID of a resource from a CloudFormation stack")
parser.add_argument("--stack-name", help="Name of the CloudFormation stack")
parser.add_argument("--logical-id", help="Logical ID of the resource")

args = parser.parse_args()

stack_name = args.stack_name
logical_id = args.logical_id

cloudformation = boto3.client('cloudformation')
response = cloudformation.describe_stack_resources(
    StackName=stack_name,
    LogicalResourceId=logical_id
)
if len(response['StackResources']) == 1:
    print(response['StackResources'][0]['PhysicalResourceId'])
else:
    raise Exception("Resource not found")