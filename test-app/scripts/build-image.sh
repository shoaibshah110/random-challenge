#!/bin/bash

function usage {
    echo "Usage: build.sh <imageTag>"
}

function main {
    if [ -z "$1" ]; then
       if [ -z "$imageTag" ]; then
           usage
           exit 1
       fi
    else
        imageTag="$1"
    fi

    echo "Building image with tag: $imageTag"
    docker build -t $imageTag ../
    if [ $? -ne 0 ]; then
        echo "Failed to build image"
    else
        echo "Image built successfully"
    fi
}
main "$@"
