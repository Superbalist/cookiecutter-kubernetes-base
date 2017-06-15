#!/usr/bin/env bash
#
# Tests whether minikube works

set -efu
set -o pipefail

TESTS_DIR=$(dirname "$(python3 -c "import os; print(os.path.realpath('$0'))")")
BASE_DIR=$(dirname "${TESTS_DIR}")

cookiecutter ./ --no-input --overwrite-if-exists
cd "${BASE_DIR}/name_of_the_project"

make test

cd "${BASE_DIR}"
rm -rf name_of_the_project
