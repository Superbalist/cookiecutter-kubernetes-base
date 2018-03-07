#!/usr/bin/env bash
#
# Build docker images

set -efu
set -o pipefail

SCRIPTS_DIR=$(dirname "$(python3 -c "import os; print(os.path.realpath('$0'))")")
BASE_DIR=$(dirname "${SCRIPTS_DIR}")

# Disabling this shellcheck. See https://github.com/koalaman/shellcheck/issues/769
# shellcheck disable=SC1091,SC1090
. "${SCRIPTS_DIR}/_common.sh" "${1:-}"

docker build --pull -t "${IMAGE_URL}" "${BASE_DIR}"

if [[ -n "${PROJECT_ID}" ]]; then
  announce "Started a build for ${IMAGE_URL} :ferry:"

  gcloud --project "${PROJECT_ID}" docker -- push "${IMAGE_URL}"

  announce "${IMAGE_URL} Build complete! :tada:"
fi
