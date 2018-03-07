#!/usr/bin/env bash
#
# Start a K8s pod that runs migrations on the project

set -efu
set -o pipefail

SCRIPTS_DIR=$(dirname "$(python3 -c "import os; print(os.path.realpath('$0'))")")
BASE_DIR=$(dirname "${SCRIPTS_DIR}")
KUBERNETES_DIR="${BASE_DIR}/kubernetes"
KUBERNETES_BUILD_DIR="${KUBERNETES_DIR}/build"

# Disabling this shellcheck. See https://github.com/koalaman/shellcheck/issues/769
# shellcheck disable=SC1091,SC1090
. "${SCRIPTS_DIR}/_build.sh" "${1:-}"

set +f
rm -f "${KUBERNETES_DIR}"/*.yml
set -f

POD_TEMPLATE="${KUBERNETES_BUILD_DIR}/pod-migration.yml"
jinja2 "${KUBERNETES_DIR}/pod-migration-base.yml.j2" > "${POD_TEMPLATE}"

POD_NAME="${REPOSITORY}-migration"

if "${ANNOUNCE_ENABLED}"; then
  announce "Starting to run migration of ${IMAGE_URL} :ferry:"
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

echo "Starting to run migration:"
kubectl create -f "${POD_TEMPLATE}"

while true; do
  POD_STATUS=$(kubectl get -f "${POD_TEMPLATE}" -a -o=jsonpath='{.status.phase}')

  case $POD_STATUS in
    Succeeded)
      echo
      echo "Migration completed!"
      echo
      break
      ;;
    Failed)
      echo
      echo 'Migration seems to have failed'
      echo
      exit 1
      ;;
    Running)
      echo "*** ATTACHING TO POD DOING MIGRATION ***"
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
  announce "${IMAGE_URL} Migration complete! :tada:"
fi
