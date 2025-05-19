import boto3
import argparse

parser = argparse.ArgumentParser(description="Generate github token")
parser.add_argument("--role-arn", help="Arn of the role to be assumed")
parser.add_argument("--session-name", help="Name of the session")
args = parser.parse_args()

sts_client = boto3.client('sts')

response = sts_client.assume_role(
    RoleArn=args.role_arn,
    RoleSessionName=args.session_name,
    DurationSeconds=3600
)

creds = response['Credentials']

print(f"export AWS_ACCESS_KEY_ID='{creds['AccessKeyId']}'")
print(f"export AWS_SECRET_ACCESS_KEY='{creds['SecretAccessKey']}'")
print(f"export AWS_SESSION_TOKEN='{creds['SessionToken']}'")

