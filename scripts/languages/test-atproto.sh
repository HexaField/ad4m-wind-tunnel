#!/usr/bin/env bash
# test-atproto.sh — AT Protocol Link Language integration test
# Infrastructure: AT Protocol PDS (docker-compose.atproto.yml)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
source "$SCRIPT_DIR/../common.sh"
load_config

INFRA_HOST="${INFRA_HOST:-$DEVICE_A_HOST}"
INFRA_USER="${INFRA_USER:-$DEVICE_A_USER}"

setup_atproto_infra() {
    echo "  Setting up AT Protocol PDS..."
    start_infra "docker-compose.atproto.yml" "$INFRA_HOST" "$INFRA_USER"
    wait_http "${ATPROTO_PDS_URL:-http://$INFRA_HOST:2583}" 30
}

teardown_atproto_infra() {
    echo "  Tearing down AT Protocol PDS..."
    stop_infra "docker-compose.atproto.yml" "$INFRA_HOST" "$INFRA_USER"
}

run_standard_tests "atproto" "${LANG_ATPROTO:-}" setup_atproto_infra teardown_atproto_infra
