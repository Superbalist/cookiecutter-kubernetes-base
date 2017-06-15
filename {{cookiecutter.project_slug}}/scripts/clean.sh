#!/usr/bin/env bash
#
# Delete the deployments, services and pods of the project along with it's data

set -efu
set -o pipefail

SCRIPTS_DIR=$(dirname "$(python3 -c "import os; print(os.path.realpath('$0'))")")

# Disabling this shellcheck. See https://github.com/koalaman/shellcheck/issues/769
# shellcheck disable=SC1091,SC1090
. "${SCRIPTS_DIR}/_common.sh" dev

kubectl delete deploy,svc -l app="${APP_NAME}" --now --force
minikube ssh -- "sudo rm -rf /data/${APP_NAME}-*"
