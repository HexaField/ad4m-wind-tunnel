#!/usr/bin/env bash
# test-matrix.sh — Matrix Link Language integration test
# Infrastructure: Matrix homeserver / Conduit (docker-compose.matrix.yml)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
source "$SCRIPT_DIR/../common.sh"
load_config

INFRA_HOST="${INFRA_HOST:-$DEVICE_A_HOST}"
INFRA_USER="${INFRA_USER:-$DEVICE_A_USER}"

setup_matrix_infra() {
    echo "  Setting up Matrix homeserver..."
    start_infra "docker-compose.matrix.yml" "$INFRA_HOST" "$INFRA_USER"
    wait_http "${MATRIX_HOMESERVER:-http://$INFRA_HOST:6167}" 30
}

teardown_matrix_infra() {
    echo "  Tearing down Matrix homeserver..."
    stop_infra "docker-compose.matrix.yml" "$INFRA_HOST" "$INFRA_USER"
}

run_standard_tests "matrix" "${LANG_MATRIX:-}" setup_matrix_infra teardown_matrix_infra
