#!/usr/bin/env bash
#
# Get a list of pods, deployments and services belonging to the project

set -efu
set -o pipefail

SCRIPTS_DIR=$(dirname "$(python3 -c "import os; print(os.path.realpath('$0'))")")

# Disabling this shellcheck. See https://github.com/koalaman/shellcheck/issues/769
# shellcheck disable=SC1091,SC1090
. "${SCRIPTS_DIR}/_common.sh" "${1:-}"

kubectl get deployments,pods,services -l app="${APP_NAME}"
