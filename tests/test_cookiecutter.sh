#!/usr/bin/env bash
#
# Tests whether cookiecutter works

set -efu
set -o pipefail

TESTS_DIR=$(dirname "$(python3 -c "import os; print(os.path.realpath('$0'))")")
BASE_DIR=$(dirname "${TESTS_DIR}")

cookiecutter ./ --no-input --overwrite-if-exists

rm -rf name_of_the_project
