#!/usr/bin/env bash
# test-ipfs.sh — IPFS Link Language integration test
# Infrastructure: IPFS / kubo daemons (docker-compose.ipfs.yml)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
source "$SCRIPT_DIR/../common.sh"
load_config

INFRA_HOST="${INFRA_HOST:-$DEVICE_A_HOST}"
INFRA_USER="${INFRA_USER:-$DEVICE_A_USER}"

setup_ipfs_infra() {
    echo "  Setting up IPFS daemons..."
    start_infra "docker-compose.ipfs.yml" "$INFRA_HOST" "$INFRA_USER"
    wait_http "${IPFS_API_A:-http://$INFRA_HOST:5001}/api/v0/id" 30

    # If Device B needs its own IPFS node, start it there too
    if [[ "${IPFS_API_B:-}" =~ $DEVICE_B_HOST ]]; then
        echo "  Starting IPFS on Device B..."
        start_infra "docker-compose.ipfs.yml" "$DEVICE_B_HOST" "$DEVICE_B_USER"
        wait_http "${IPFS_API_B}/api/v0/id" 30
    fi
}

teardown_ipfs_infra() {
    echo "  Tearing down IPFS daemons..."
    stop_infra "docker-compose.ipfs.yml" "$INFRA_HOST" "$INFRA_USER"
    if [[ "${IPFS_API_B:-}" =~ $DEVICE_B_HOST ]]; then
        stop_infra "docker-compose.ipfs.yml" "$DEVICE_B_HOST" "$DEVICE_B_USER"
    fi
}

run_standard_tests "ipfs" "${LANG_IPFS:-}" setup_ipfs_infra teardown_ipfs_infra
