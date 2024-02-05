#!/bin/bash

function usage {
    echo "Usage: ./push-docker-image.sh <accountId> <dockerImageId>"
}

function main {

    if [ -z "$1" ]; then
       if [ -z "$accountId" ]; then
        usage
        exit 1
        fi
    else
        accountId=$1
    fi

    if [ -z "$2" ]; then
        if [ -z "$dockerImageId" ]; then
        usage
        exit 1
        fi
    else
        region=$2
    fi

    echo "Authenticating Docker to Amazon ECR..."
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $accountId.dkr.ecr.us-east-1.amazonaws.com

    echo "Tagging the Docker image..."
    docker tag $dockerImageId $accountId.dkr.ecr.us-east-1.amazonaws.com/preprod-images

    echo "Pushing the Docker image to Amazon ECR..."
    docker push $accountId.dkr.ecr.us-east-1.amazonaws.com/preprod-images

    if [ $? -eq 0 ]; then
        echo "Docker image pushed to Amazon ECR successfully."
    else
        echo "Failed to push Docker image to Amazon ECR."
    fi
}
main "$@"
