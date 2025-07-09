#!/bin/bash

# prestop.sh - Handle ECS task termination with scaling logic

set -e

echo "Pre-stop script started at $(date)"

# Get ECS metadata
if [ -n "$ECS_CONTAINER_METADATA_URI_V4" ]; then
    echo "Getting ECS task metadata..."
    TASK_METADATA=$(curl -s "${ECS_CONTAINER_METADATA_URI_V4}/task")
    TASK_ARN=$(echo "$TASK_METADATA" | jq -r '.TaskARN')
    CLUSTER_ARN=$(echo "$TASK_METADATA" | jq -r '.Cluster')
    
    # Extract cluster name from ARN
    CLUSTER_NAME=$(echo "$CLUSTER_ARN" | sed 's/.*cluster\///')
    
    echo "Task ARN: $TASK_ARN"
    echo "Cluster: $CLUSTER_NAME"
else
    echo "Warning: ECS metadata not available"
fi

# Required environment variables
if [ -z "$AWS_REGION" ]; then
    echo "Error: AWS_REGION not set"
    exit 1
fi

if [ -z "$ECS_SERVICE_NAME" ]; then
    echo "Error: ECS_SERVICE_NAME not set"
    exit 1
fi

# Set defaults
REGION=${AWS_DEFAULT_REGION}
SERVICE_NAME=${ECS_SERVICE_NAME}
SHUTDOWN_REASON=${SEMAPHORE_AGENT_SHUTDOWN_REASON:-"UNKNOWN"}

echo "Shutdown reason: $SHUTDOWN_REASON"
echo "Region: $REGION"
echo "Service: $SERVICE_NAME"

# ECS Application Auto Scaling logic
if [[ $SHUTDOWN_REASON == "IDLE" || $SHUTDOWN_REASON == "JOB_FINISHED" ]]; then
    echo "IDLE/JOB_FINISHED shutdown detected - reducing desired capacity"
    
    # Get current desired count
    echo "Getting current service desired count..."
    CURRENT_COUNT=$(aws ecs describe-services \
        --region "$REGION" \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --query 'services[0].desiredCount' \
        --output text 2>/dev/null)
    
    if [ "$CURRENT_COUNT" != "None" ] && [ "$CURRENT_COUNT" -gt 0 ]; then
        # Calculate new desired count (decrement by 1)
        NEW_COUNT=$((CURRENT_COUNT - 1))
        
        echo "Reducing desired count from $CURRENT_COUNT to $NEW_COUNT"
        
        # Update service with reduced desired count
        aws ecs update-service \
            --region "$REGION" \
            --cluster "$CLUSTER_NAME" \
            --service "$SERVICE_NAME" \
            --desired-count "$NEW_COUNT" \
            --no-cli-pager
        
        echo "Successfully reduced desired count"
    else
        echo "Current count is $CURRENT_COUNT, not reducing further"
    fi
    
else
    echo "Non-IDLE/Non-JOB_FINISHED shutdown ($SHUTDOWN_REASON) - stopping task but maintaining desired count"
    
    if [ -n "$TASK_ARN" ]; then
        # Stop the current task (ECS will replace it automatically)
        echo "Stopping current task..."
        aws ecs stop-task \
            --region "$REGION" \
            --cluster "$CLUSTER_NAME" \
            --task "$TASK_ARN" \
            --reason "Agent shutdown: $SHUTDOWN_REASON" \
            --no-cli-pager
        
        echo "Task stop initiated - ECS will start replacement"
    else
        echo "Warning: Task ARN not available, cannot stop specific task"
    fi
fi

echo "Pre-stop script completed at $(date)"