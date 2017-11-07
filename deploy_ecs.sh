#!/bin/bash

CLUSTER=$1
SERVICE=$2
REPOSITORY=$3
BUILD_ID=$4

TARGET_REPOSITORY=${REPOSITORY}/${SERVICE}

# for backup
docker tag ${SERVICE} ${TARGET_REPOSITORY}:${BUILD_ID}
docker push ${TARGET_REPOSITORY}:${BUILD_ID}

# for deploy
docker tag ${IMAGE_NAME} ${TARGET_REPOSITORY}:latest
docker push ${TARGET_REPOSITORY}:latest

# update task definition
aws ecs register-task-definition --cli-input-json file://${SERVICE}.json --region "ap-northeast-1"

# update service
aws ecs update-service --service ${SERVICE} --task-definition ${SERVICE} --cluster ${CLUSTER_NAME} --region "ap-northeast-1"
