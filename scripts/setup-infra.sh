#!/usr/bin/env bash
# setup-infra.sh — Start required infrastructure for specific protocols
# Usage: ./scripts/setup-infra.sh [protocol|all]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
load_config

INFRA_DIR="$REPO_DIR/infra"
# Infrastructure host defaults to Device A
INFRA_HOST="${INFRA_HOST:-$DEVICE_A_HOST}"
INFRA_USER="${INFRA_USER:-$DEVICE_A_USER}"

start_protocol_infra() {
    local protocol="$1"
    local compose_file="docker-compose.${protocol}.yml"

    if [[ ! -f "$INFRA_DIR/$compose_file" ]]; then
        echo "  No infrastructure needed for $protocol (P2P)"
        return 0
    fi

    echo "Starting infrastructure for $protocol..."
    start_infra "$compose_file" "$INFRA_HOST" "$INFRA_USER"

    # Protocol-specific readiness checks
    case "$protocol" in
        nostr)
            local relay_host relay_port
            relay_host=$(echo "${NOSTR_RELAY_URL:-ws://$INFRA_HOST:7777}" | sed 's|ws://||;s|/.*||;s|:.*||')
            relay_port=$(echo "${NOSTR_RELAY_URL:-ws://$INFRA_HOST:7777}" | grep -o ':[0-9]*' | tr -d ':')
            wait_ws "$relay_host" "${relay_port:-7777}" 30
            ;;
        matrix)
            wait_http "${MATRIX_HOMESERVER:-http://$INFRA_HOST:6167}" 30
            ;;
        solid)
            wait_http "${SOLID_POD_URL:-http://$INFRA_HOST:3000}" 30
            ;;
        atproto)
            wait_http "${ATPROTO_PDS_URL:-http://$INFRA_HOST:2583}" 30
            ;;
        ipfs)
            wait_http "${IPFS_API_A:-http://$INFRA_HOST:5001}/api/v0/id" 30
            ;;
    esac

    echo "  ✅ $protocol infrastructure ready"
}

protocol="${1:-all}"

if [[ "$protocol" == "all" ]]; then
    for p in nostr matrix solid atproto ipfs; do
        start_protocol_infra "$p"
    done
else
    start_protocol_infra "$protocol"
fi

echo "=== Infrastructure setup complete ==="
