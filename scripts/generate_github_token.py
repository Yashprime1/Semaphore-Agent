import os
import jwt
import time
import argparse
import requests

parser = argparse.ArgumentParser(description="Generate github token")
parser.add_argument("--client-id", help="GitHub bot id")
parser.add_argument("--private-key", help="GitHub private access key id")
parser.add_argument("--installation-id", help="GitHub app installation id")
args = parser.parse_args()

client_id = args.client_id
signing_key = args.private_key.replace("\\n", "\n")
installation_id = args.installation_id

print(client_id, signing_key, installation_id)

payload = {
    'iat': int(time.time()),
    'exp': int(time.time()) + 600,
    'iss': client_id
}
encoded_jwt = jwt.encode(payload, signing_key, algorithm='RS256')
if isinstance(encoded_jwt, bytes):
    encoded_jwt = str(encoded_jwt, 'utf-8')

url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
headers = {
    "Accept": "application/vnd.github+json",
    "Authorization": f"Bearer {encoded_jwt}",
    "X-GitHub-Api-Version": "2022-11-28"
}

response = requests.post(url, headers=headers)
response.raise_for_status()
github_token = response.json().get("token")
print(github_token)
