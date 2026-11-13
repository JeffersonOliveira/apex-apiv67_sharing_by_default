#!/usr/bin/env bash
# Runs all local tests with coverage. Extra arguments go to the sf command,
# for example: ./scripts/run-tests.sh -o lab
set -euo pipefail

sf apex run test --test-level RunLocalTests --code-coverage --result-format human --wait 10 "$@"
