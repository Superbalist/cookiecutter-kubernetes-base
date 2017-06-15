#!/usr/bin/env bash
#
# Opens a bash shell on a pod

set -efu
set -o pipefail

SCRIPTS_DIR=$(dirname "$(python3 -c "import os; print(os.path.realpath('$0'))")")

# Disabling this shellcheck. See https://github.com/koalaman/shellcheck/issues/769
# shellcheck disable=SC1091,SC1090
. "${SCRIPTS_DIR}/_common.sh" "${1:-}"

get_pod "${2:-}"
kubectl exec -it "${POD}" -- bash
