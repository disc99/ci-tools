#!/bin/bash

CLUSTER=$1
SERVICE=$2
ECR=$3
TASK_DEFINITION_PATH=$4
BUILD_ID=$5

REPOSITORY=${ECR}/${SERVICE}
TIMEOUT=600
REGION=ap-northeast-1

# wait function
function waitForServiceUpdate {
  DEPLOYMENT_SUCCESS="false"
  every=2
  i=0
  echo "Waiting for service deployment to complete..."
  while [ $i -lt $TIMEOUT ]
  do
    NUM_DEPLOYMENTS=$(aws ecs describe-services --services $SERVICE --cluster $CLUSTER --region ${REGION} | jq "[.services[].deployments[]] | length")

    # Wait to see if more than 1 deployment stays running
    # If the wait time has passed, we need to roll back
    if [ "$NUM_DEPLOYMENTS" = "1" ]; then
      echo "Service deployment successful."
      DEPLOYMENT_SUCCESS="true"
      # Exit the loop.
      i=$TIMEOUT
    else
      sleep $every
      i=$(( $i + $every ))
    fi
  done

  if [[ "${DEPLOYMENT_SUCCESS}" != "true" ]]; then
    exit 1
  fi
}


# login ECR
login="$(aws ecr get-login --region ${REGION})"
${login}

# for backup
docker tag ${SERVICE} ${REPOSITORY}:${BUILD_ID}
docker push ${REPOSITORY}:${BUILD_ID}

# for deploy
docker tag ${SERVICE} ${REPOSITORY}:latest
docker push ${REPOSITORY}:latest

# update task definition
aws ecs register-task-definition --cli-input-json file://${TASK_DEFINITION_PATH}/${SERVICE}.json --region ${REGION}

# update service
aws ecs update-service --service ${SERVICE} --task-definition ${SERVICE} --cluster ${CLUSTER} --region ${REGION}

# wait
waitForServiceUpdate
