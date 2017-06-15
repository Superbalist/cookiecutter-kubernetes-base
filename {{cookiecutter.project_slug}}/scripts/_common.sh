#!/usr/bin/env bash
#
# Variables used by other scripts

set -efu
set -o pipefail

REPOSITORY="{{ cookiecutter.project_k8s_label }}"
APP_NAME="{{ cookiecutter.project_k8s_label }}"
SLACKBOT_URL="{{ cookiecutter.slackbot_webhook_url }}"
CURRENT_USER=$(whoami)
OS="$(uname -s)"

ENVIRONMENT=${1:-}

if [[ -z "${ENVIRONMENT}" ]]; then
  echo 'Please provide an environment when running this command'
  echo 'e.g. scripts/logs.sh staging'
  exit 1;
fi

case "${ENVIRONMENT}" in
  production)
    PROJECT_ID="{{ cookiecutter.google_project_id_production }}"
    PROJECT_ZONE="{{ cookiecutter.google_project_zone_production }}"
    CLUSTER="hive"
    KUBECTL_CONTEXT="gke_${PROJECT_ID}_${PROJECT_ZONE}_${CLUSTER}"
    SLACK_CHANNEL="{{ cookiecutter.slack_notification_channel_prod }}"
    ANNOUNCE_PREFIX="production"
    ANNOUNCE_ENABLED=true
    ;;

  staging)
    PROJECT_ID="{{ cookiecutter.google_project_id_staging }}"
    PROJECT_ZONE="{{ cookiecutter.google_project_zone_staging }}"
    CLUSTER="hive"
    KUBECTL_CONTEXT="gke_${PROJECT_ID}_${PROJECT_ZONE}_${CLUSTER}"
    SLACK_CHANNEL="{{ cookiecutter.slack_notification_channel_staging }}"
    ANNOUNCE_PREFIX=":construction: staging"
    ANNOUNCE_ENABLED=true
    ;;

  dev)
    eval "$(minikube docker-env)"
    PROJECT_ID=""
    KUBECTL_CONTEXT="minikube"
    ANNOUNCE_ENABLED=false
    ;;

  *)
    echo "Try one of the following environments:"
    echo "    dev, staging, production"
    exit 1
    ;;
esac

if "${ANNOUNCE_ENABLED}"; then
  ANNOUNCE_PREFIX="${ANNOUNCE_PREFIX}/${REPOSITORY}"
  ANNOUNCE_SUFFIX="(by *${CURRENT_USER}*)"
fi

case "$KUBECTL_CONTEXT" in
  "")
    echo "Not switching context, we're already there"
    ;;

  minikube)
    eval "$(minikube docker-env)"
    if [[ $(kubectl config use-context "${KUBECTL_CONTEXT}") ]]; then
      echo "Successfully changed context: ${KUBECTL_CONTEXT}"
    else
      echo "Looks like you aren't running minikube"
      exit 1
    fi
    ;;

  *)
    echo "Attempting to fetch context from gcloud: ${KUBECTL_CONTEXT}"
    gcloud --project "${PROJECT_ID}" container clusters get-credentials "${CLUSTER}" --zone "${PROJECT_ZONE}"
    kubectl config use-context "${KUBECTL_CONTEXT}"
    echo "Successfully changed context: ${KUBECTL_CONTEXT}"
    # We only switch context to check if the client has the necessary context in
    # their '~/.kube/config', as soon as we've written a CLI that reads that YAML
    # file we won't need to do this anymore.
    #
    # We explicitly set context for all 'kubectl' calls, so this is okay.
    set +e
    eval "$(minikube docker-env)"
    kubectl config use-context minikube
    set -e
    ;;
esac

SCRIPTS_DIR=$(dirname "$(python3 -c "import os; print(os.path.realpath('$0'))")")
BASE_DIR=$(dirname "${SCRIPTS_DIR}")

if [[ "${ENVIRONMENT}" == 'dev' ]]; then
  SOURCE_PATH="${BASE_DIR}/src"
  export SOURCE_PATH
fi

cd "${BASE_DIR}"
HASH=$(git rev-parse --short HEAD)

if [[ -z "$PROJECT_ID" ]]; then
  IMAGE_URL="${REPOSITORY}:${HASH}"
else
  IMAGE_URL="{{ cookiecutter.google_container_registry }}/${PROJECT_ID}/${REPOSITORY}:${HASH}"
fi

# Disabling this shellcheck. See https://github.com/koalaman/shellcheck/issues/769
# shellcheck disable=SC1091,SC1090
. "${SCRIPTS_DIR}/_functions.sh"

export ANNOUNCE_ENABLED
export ANNOUNCE_PREFIX
export ANNOUNCE_SUFFIX
export APP_NAME
export CURRENT_USER
export ENVIRONMENT
export HASH
export IMAGE_URL
export KUBECTL_CONTEXT
export OS
export PROJECT_ID
export REPOSITORY
export SLACKBOT_URL
export SLACK_CHANNEL
export announce
export check_all_deployments
export get_pod
export git_status
export kubectl
