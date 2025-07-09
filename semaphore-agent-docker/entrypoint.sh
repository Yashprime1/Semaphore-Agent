#!/bin/bash

# Set default values for environment variables
SEMAPHORE_ENDPOINT=${SEMAPHORE_ENDPOINT:-""}
SEMAPHORE_AGENT_TOKEN=${SEMAPHORE_AGENT_TOKEN:-""}
DISCONNECT_AFTER_JOB=${DISCONNECT_AFTER_JOB:-"true"}
DISCONNECT_AFTER_IDLE_TIMEOUT=${DISCONNECT_AFTER_IDLE_TIMEOUT:-"30"}
SHUTDOWN_HOOK_PATH=${SHUTDOWN_HOOK_PATH:-"/opt/semaphore/shutdown"}
SSH_KEYS_PARAMETER_NAME=${SSH_KEYS_PARAMETER_NAME:-""}
SEMAPHORE_GIT_CACHE_AGE=${SEMAPHORE_GIT_CACHE_AGE:-"86400"}
SEMAPHORE_CACHE_BACKEND=${SEMAPHORE_CACHE_BACKEND:-"s3"}
SEMAPHORE_CACHE_S3_BUCKET=${SEMAPHORE_CACHE_S3_BUCKET:-""}

# Check if required env variables are set
if [[ -z "$SEMAPHORE_ENDPOINT" ]]; then
    echo "Error: SEMAPHORE_ENDPOINT is required"
    exit 1
fi
if [[ -z "$SEMAPHORE_AGENT_TOKEN" ]]; then
    echo "Error: SEMAPHORE_AGENT_TOKEN is required"
    exit 1
fi
if [[ -z "$SSH_KEYS_PARAMETER_NAME" ]]; then
    echo "Error: SSH_KEYS_PARAMETER_NAME is required"
    exit 1
fi
if [[ -z "$SEMAPHORE_CACHE_S3_BUCKET" ]]; then
    echo "Error: SEMAPHORE_CACHE_S3_BUCKET is required"
    exit 1
fi



# Ensure the directory exists
mkdir -p /opt/semaphore

# Generate the semaphore-agent.yml configuration file
cat > /opt/semaphore/semaphore-agent.yml << EOF
endpoint: ${SEMAPHORE_ENDPOINT}
token: ${SEMAPHORE_AGENT_TOKEN}
sshKeysParameterName: ${SSH_KEYS_PARAMETER_NAME}
shutdown-hook-path: ${SHUTDOWN_HOOK_PATH}
disconnect-after-job: ${DISCONNECT_AFTER_JOB}
disconnect-after-idle-timeout: ${DISCONNECT_AFTER_IDLE_TIMEOUT}
EOF

echo "Configuration file generated:"
cat /opt/semaphore/semaphore-agent.yml

# Start the semaphore agent
exec /opt/semaphore/agent start --config-file /opt/semaphore/semaphore-agent.yml