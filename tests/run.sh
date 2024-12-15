#!/usr/bin/env bash

# Setup shell for running tests.
set -euo pipefail

# Ensure that any reunning containers are stopped and removed on exit.
clean_exit() {
  if [ -x "tests/.env" ]; then rm tests/.env; fi
}
trap clean_exit EXIT

run_test() {
  echo -e "Running "$1"...\n"
  bash -c "set -euo pipefail; . ""$1"
  echo -e "Done\n\n"
}

# Run tests
run_test test-env-sh.sh
run_test test-networks.sh
