#!/bin/bash

CLUSTER=$1
SERVICE=$2
ECR=$3
BUILD_ID=$4

REPOSITORY=${ECR}/${SERVICE}

# for backup
docker tag ${SERVICE} ${REPOSITORY}:${BUILD_ID}
docker push ${REPOSITORY}:${BUILD_ID}

# for deploy
docker tag ${IMAGE_NAME} ${REPOSITORY}:latest
docker push ${REPOSITORY}:latest

# update task definition
aws ecs register-task-definition --cli-input-json file://${SERVICE}.json --region "ap-northeast-1"

# update service
aws ecs update-service --service ${SERVICE} --task-definition ${SERVICE} --cluster ${CLUSTER_NAME} --region "ap-northeast-1"
