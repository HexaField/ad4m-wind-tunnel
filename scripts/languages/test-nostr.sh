#!/usr/bin/env bash
# test-nostr.sh — Nostr Link Language integration test
# Infrastructure: Nostr relay (docker-compose.nostr.yml)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
source "$SCRIPT_DIR/../common.sh"
load_config

INFRA_HOST="${INFRA_HOST:-$DEVICE_A_HOST}"
INFRA_USER="${INFRA_USER:-$DEVICE_A_USER}"

setup_nostr_infra() {
    echo "  Setting up Nostr relay..."
    start_infra "docker-compose.nostr.yml" "$INFRA_HOST" "$INFRA_USER"
    local relay_host relay_port
    relay_host=$(echo "${NOSTR_RELAY_URL:-ws://$INFRA_HOST:7777}" | sed 's|ws://||;s|/.*||;s|:.*||')
    relay_port=$(echo "${NOSTR_RELAY_URL:-ws://$INFRA_HOST:7777}" | grep -o ':[0-9]*' | tr -d ':')
    wait_ws "$relay_host" "${relay_port:-7777}" 30
}

teardown_nostr_infra() {
    echo "  Tearing down Nostr relay..."
    stop_infra "docker-compose.nostr.yml" "$INFRA_HOST" "$INFRA_USER"
}

run_standard_tests "nostr" "${LANG_NOSTR:-}" setup_nostr_infra teardown_nostr_infra
