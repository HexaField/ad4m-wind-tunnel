#!/usr/bin/env bash
# teardown.sh — Stop executors and infrastructure
# Usage: ./scripts/teardown.sh [--executors] [--infra] [--all]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
load_config

INFRA_HOST="${INFRA_HOST:-$DEVICE_A_HOST}"
INFRA_USER="${INFRA_USER:-$DEVICE_A_USER}"

teardown_executors() {
    echo "=== Stopping executors ==="

    echo "  Stopping executor on Device A ($DEVICE_A_HOST)..."
    run_on "$DEVICE_A_HOST" "$DEVICE_A_USER" \
        "pkill -f 'ad4m-executor.*--port $DEVICE_A_PORT' || true" 2>/dev/null || true

    echo "  Stopping executor on Device B ($DEVICE_B_HOST)..."
    run_on "$DEVICE_B_HOST" "$DEVICE_B_USER" \
        "pkill -f 'ad4m-executor.*--port $DEVICE_B_PORT' || true" 2>/dev/null || true

    echo "  ✅ Executors stopped"
}

teardown_infra() {
    echo "=== Stopping infrastructure ==="

    for compose_file in "$REPO_DIR"/infra/docker-compose.*.yml; do
        if [[ -f "$compose_file" ]]; then
            stop_infra "$(basename "$compose_file")" "$INFRA_HOST" "$INFRA_USER"
        fi
    done

    echo "  ✅ Infrastructure stopped"
}

clean_data() {
    echo "=== Cleaning test data ==="

    echo "  Cleaning Device A..."
    run_on "$DEVICE_A_HOST" "$DEVICE_A_USER" "rm -rf $EXECUTOR_DATA_DIR" 2>/dev/null || true

    echo "  Cleaning Device B..."
    run_on "$DEVICE_B_HOST" "$DEVICE_B_USER" "rm -rf $EXECUTOR_DATA_DIR" 2>/dev/null || true

    echo "  ✅ Test data cleaned"
}

# Parse arguments
do_executors=false
do_infra=false
do_clean=false

if [[ $# -eq 0 ]]; then
    do_executors=true
    do_infra=true
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --executors) do_executors=true ;;
        --infra)     do_infra=true ;;
        --clean)     do_clean=true ;;
        --all)       do_executors=true; do_infra=true; do_clean=true ;;
        *)           echo "Usage: $0 [--executors] [--infra] [--clean] [--all]"; exit 1 ;;
    esac
    shift
done

[[ "$do_executors" == true ]] && teardown_executors
[[ "$do_infra" == true ]]     && teardown_infra
[[ "$do_clean" == true ]]     && clean_data

echo ""
echo "=== Teardown complete ==="
