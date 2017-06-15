#!/usr/bin/env bash
#
# Library of common repo-agnostic functions

set -efu
set -o pipefail

SCRIPTS_DIR=$(dirname "$(python3 -c "import os; print(os.path.realpath('$0'))")")
BASE_DIR=$(dirname "${SCRIPTS_DIR}")

################################################
# Fixed context for kubectl commands
# GLOBALS:
#   KUBECTL_CONTEXT
# Return:
#   None
################################################
kubectl () {
  $(which kubectl) --context "${KUBECTL_CONTEXT}" "$@"
}

#######################################
# Send a message to a slack channel
# Globals:
#   SLACKBOT_URL
#   ANNOUNCE_PREFIX
#   ANNOUNCE_SUFFIX
#   SLACK_CHANNEL
# Arguments:
#   Message to send
# Return:
#   None
#######################################
announce () {
  if [[ ! -z "${SLACKBOT_URL:-}" ]]; then
    curl --data "*${ANNOUNCE_PREFIX}:* $1 ${ANNOUNCE_SUFFIX}" "${SLACKBOT_URL}&channel=${SLACK_CHANNEL}";
  fi
}

#######################################
# Get a pod in the project
# Globals:
#   APP_NAME
# Arguments:
#   Partial name of the pod to find
# Return:
#   pod
#######################################
get_pod () {
  local pods
  pods=$(kubectl get po -l app="${APP_NAME}" -o=jsonpath='{.items[*].metadata.name}')
  local example_pod
  example_pod=$(echo "$pods" | awk '{ print $1 }')

  local prefix=${1:-}

  if [[ -z "$prefix" ]]; then
    echo 'Please provide a pod name or prefix'
    echo "e.g. ${example_pod}"
    exit 1
  fi

  echo "Looking for pods that match ${prefix}"

  for POD in $pods; do
    if echo "${POD}" | grep -q "${prefix}"; then
      echo "Connecting to pod ${POD}"
      return
    fi
  done

  echo 'No pods found'
  exit 1
}

###############################################################
# Check the rollout status for the specified deployments
# Arguments:
#   A list of deployments
# Return:
#   None
###############################################################
check_deployments() {
  deployments=( "$@" )
  for deployment in "${deployments[@]}"; do
    (
      kubectl rollout status "${deployment}"
    ) &
  done
}

################################################
# Check the rollout status all deployments
# Arguments:
#   APPS - A list of applications
# Return:
#   None
################################################
check_all_deployments () {
  DEPLOYMENTS=$(kubectl get deployments -o name -l "app=${APP_NAME}")
  check_deployments "${DEPLOYMENTS}"

  wait
}

#############################################################################
# Fixed environment, hash, image, source and config for jinja commands
# GLOBALS:
#   ENVIRONMENT
#   HASH
#   IMAGE_URL
#   SOURCE_PATH
#   BASE_DIR
# Return:
#   None
#############################################################################
jinja2 () {
  if [[ "${ENVIRONMENT}" == "dev" ]]; then
    $(which jinja2) --strict --format=yml -D environment="${ENVIRONMENT}" -D git_sha="${HASH}" \
      -D image_url="${IMAGE_URL}" -D source_path="${SOURCE_PATH}" "$@" "${BASE_DIR}/config.yml"
  else
    $(which jinja2) --strict --format=yml -D environment="${ENVIRONMENT}" -D git_sha="${HASH}" \
      -D image_url="${IMAGE_URL}" "$@" "${BASE_DIR}/config.yml"
  fi
}

export announce
export check_all_deployments
export get_pod
export kubectl
export jinja2
