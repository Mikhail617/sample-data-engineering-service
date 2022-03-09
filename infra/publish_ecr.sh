#!/bin/bash

# Publish a container to a given repository in the AWS ECR service
# Use the --help option to see it usage

set -e

AWS_PROFILE="default"
CLUSTER_NAME="qubec-cluster"
UPDATE_SRV=0

usage() {
   cat << EOF
Usage: --dockerfile --dockerfile /path/to/dockerfile --ecr-url ecr_repo_url [--profile aws_profile] [--help]
The required --dockerfile argument takes a path to a valid Dockerfile which can be used to build the Docker image
to send to AWS container registry.
The required --ecr-url argument takes a URL of valid repository in the AWS container registry (ECR)
The optional --profile argument takes as input an AWS CLI profile stored locally (see ~/.aws/config to see the
profiles currently available in your machine)
EOF
}

while [ "$1" != "" ]; do
    case $1 in
        -p | --profile )    shift
			    AWS_PROFILE="$1"
			    ;;
        -d | --dockerfile ) shift
			    DOCKER_FILE="$1"
			    ;;
        -e | --ecr-url )    shift
			    ECR_URL="$1"
			    ;;
        -h | --help )       shift
			    usage
			    exit 
			    ;;
    esac
    shift
done

if [ -z $ECR_URL ] || [ -z $DOCKER_FILE ]; then
    usage
    exit
fi

echo "AWS profile: $AWS_PROFILE"
echo "ECR repository address: $ECR_URL"
echo "Dockerfile location to build the image: $DOCKER_FILE"

aws ecr --profile ${AWS_PROFILE} get-login-password | docker login --username AWS --password-stdin "${ECR_URL}"

docker build -t "$ECR_URL" -f ${DOCKER_FILE} .
docker tag "$ECR_URL":latest "$ECR_URL":latest
docker push "$ECR_URL":latest
@Mikhail617
Attach files by dragging & dropping, selecting or pasting them.

    © 2022 GitHub, Inc.

    Terms
    Privacy
    Security
    Status
    Docs
    Contact GitHub
    Pricing
    API
    Training
    Blog
    About

