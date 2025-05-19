import os
import boto3
import argparse

parser = argparse.ArgumentParser(description="Upload source s3 bucket contents")
parser.add_argument("--source-s3-bucket-name", help="Name of the source s3 bucket from cfstack-Init stack")
parser.add_argument("--source-s3-bucket-contents-directory-path", help="Path to the source s3 bucket contents directory")


args = parser.parse_args()

source_s3_bucket_name = args.source_s3_bucket_name
source_s3_bucket_contents_directory_path = args.source_s3_bucket_contents_directory_path

s3_client = boto3.client('s3')
for root, dirs, files in os.walk(source_s3_bucket_contents_directory_path):
    for file in files:
        if not file.startswith('.'):
            source_s3_bucket_contents_path = os.path.abspath(os.path.join(root, file))
            s3_bucket_key = os.path.relpath(source_s3_bucket_contents_path, source_s3_bucket_contents_directory_path)
            s3_client.upload_file(source_s3_bucket_contents_path, source_s3_bucket_name, s3_bucket_key)


