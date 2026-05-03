#!/usr/bin/env bash
# test-solid.sh — Solid Link Language integration test
# Infrastructure: Community Solid Server (docker-compose.solid.yml)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
source "$SCRIPT_DIR/../common.sh"
load_config

INFRA_HOST="${INFRA_HOST:-$DEVICE_A_HOST}"
INFRA_USER="${INFRA_USER:-$DEVICE_A_USER}"

setup_solid_infra() {
    echo "  Setting up Solid server..."
    start_infra "docker-compose.solid.yml" "$INFRA_HOST" "$INFRA_USER"
    wait_http "${SOLID_POD_URL:-http://$INFRA_HOST:3000}" 30
}

teardown_solid_infra() {
    echo "  Tearing down Solid server..."
    stop_infra "docker-compose.solid.yml" "$INFRA_HOST" "$INFRA_USER"
}

run_standard_tests "solid" "${LANG_SOLID:-}" setup_solid_infra teardown_solid_infra
