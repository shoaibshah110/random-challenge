#!/bin/bash

function usage {
    echo "Usage: run.sh <port> <imageTag> - use the same image tag which was passed to the build-image.sh script"
}

function main {
    if [ -z "$1" ]; then
       if [ -z "$port" ]; then
           usage
           exit 1
       fi
    else
        port=$1
    fi

    if [ -z "$2" ]; then
        if [ -z "$imageTag" ]; then
            usage
            exit 1
        fi
    else
        imageTag=$2
    fi

    echo "Creating container with port $port and image tag $imageTag"
    docker run -p $port:8000 $imageTag
}
main "$@"
