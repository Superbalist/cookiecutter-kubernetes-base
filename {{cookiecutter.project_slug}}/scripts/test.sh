#!/usr/bin/env bash
#
# Start a K8s pod that runs tests on the project

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
. "${SCRIPTS_DIR}/_build.sh" "${1:-}"

set +f
rm -f "${KUBERNETES_DIR}"/*.yml
set -f

POD_TEMPLATE="${KUBERNETES_BUILD_DIR}/pod-tests.yml"
jinja2 "${KUBERNETES_DIR}/pod-tests-base.yml.j2" > "${POD_TEMPLATE}"

POD_NAME="${REPOSITORY}-tests"

if "${ANNOUNCE_ENABLED}"; then
  announce "Starting to run tests of ${IMAGE_URL} :shipit:"
fi

echo "The pod might not exist:"
set +e
kubectl delete -f "${POD_TEMPLATE}"
set -e

echo "Waiting for pods to be cleaned up:"
while true; do
  if [[ ! "$(kubectl get -f "${POD_TEMPLATE}" -a -o=name)" ]] ; then
    break
  fi
done

echo "Starting to run tests:"
kubectl create -f "${POD_TEMPLATE}"

while true; do
  POD_STATUS=$(kubectl get -f "${POD_TEMPLATE}" -a -o=jsonpath='{.status.phase}')

  case $POD_STATUS in
    Succeeded)
      echo
      echo "Tests completed!"
      echo
      break
      ;;
    Failed)
      echo
      echo 'Tests seems to have failed'
      echo
      set +e
      kubectl logs "${POD_NAME}"
      set -e
      if "${ANNOUNCE_ENABLED}"; then
        announce "Tests for ${IMAGE_URL} seemed to have failed... :disappointed:"
        set +e
        LOG_OUTPUT=$(kubectl logs "${POD_NAME}" | grep "Tests:" )
        announce "Tests output: ${LOG_OUTPUT}"
        set -e
      fi
      exit 1
      ;;
    Running)
      echo "*** ATTACHING TO POD DOING TESTS ***"
      set +e
      kubectl attach "${POD_NAME}"
      set -e
      ;;
    Pending)
      echo "Pod still pending..."
      ;;
  esac
done

echo 'Fetcing all logs'
kubectl logs "${POD_NAME}"

mv "${POD_TEMPLATE}" "${POD_TEMPLATE}.bak"

if "${ANNOUNCE_ENABLED}"; then
  announce "${IMAGE_URL} Tests complete! :tada: :cloud:"
fi
