#!/usr/bin/env bash
#
# Deploy the project to your K8s environment

set -efu
set -o pipefail

SCRIPTS_DIR=$(dirname "$(python3 -c "import os; print(os.path.realpath('$0'))")")
BASE_DIR=$(dirname "${SCRIPTS_DIR}")
KUBERNETES_DIR="${BASE_DIR}/kubernetes"
KUBERNETES_BUILD_DIR="${KUBERNETES_DIR}/build"

# Disabling this shellcheck. See https://github.com/koalaman/shellcheck/issues/769
# shellcheck disable=SC1091,SC1090
. "${SCRIPTS_DIR}/minikube_start.sh"

# Disabling this shellcheck. See https://github.com/koalaman/shellcheck/issues/769
# shellcheck disable=SC1091,SC1090
. "${SCRIPTS_DIR}/_common.sh" "${1:-}"

if [[ ! "${ENVIRONMENT}" = "dev" ]]; then
  # Disabling this shellcheck. See https://github.com/koalaman/shellcheck/issues/769
  # shellcheck disable=SC1091,SC1090
  . "${SCRIPTS_DIR}/migrate.sh" "${1:-}"
fi

set +f
rm -f "${KUBERNETES_BUILD_DIR}"/*.yml
set -f

export IMAGE_URL

if [[ "${ENVIRONMENT}" = "dev" ]]; then
  j2 -f env "${KUBERNETES_DIR}/dev/svc.yml.j2" > "${KUBERNETES_DIR}/dev/svc.yml"
  set +e
  echo
  echo "Ignore 'already exists' errors:"
  kubectl create -f "${KUBERNETES_DIR}/dev/"
  echo
  echo "Ignore 'field is immutable' errors:"
  kubectl replace -f "${KUBERNETES_DIR}/dev/"
  set -e
fi

jinja2 -D component=app "${KUBERNETES_DIR}/deployment-base.yml.j2" > "${KUBERNETES_BUILD_DIR}/deployments.yml"

if "${ANNOUNCE_ENABLED}"; then
  announce "Starting a deploy of ${IMAGE_URL} :shipit:"
fi

if [[ "${ENVIRONMENT}" == "dev" ]]; then
  echo "Ignore 'already exists' errors:"
  set +e
  kubectl create -f "${KUBERNETES_BUILD_DIR}/"
  set -e
fi

if [[ "${ENVIRONMENT}" == "dev" ]]; then
  # Disabling this shellcheck. See https://github.com/koalaman/shellcheck/issues/769
  # shellcheck disable=SC1091,SC1090
  . "${SCRIPTS_DIR}/migrate.sh" "${1:-}"
fi

kubectl replace -f "${KUBERNETES_BUILD_DIR}/"

check_all_deployments

echo "Deployment complete!"

if "${ANNOUNCE_ENABLED}"; then
  announce "${IMAGE_URL} deploy complete! :tada: :cloud:"
fi
