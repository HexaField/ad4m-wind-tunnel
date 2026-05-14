#!/usr/bin/env bash
# setup-executor.sh — Install and start an AD4M executor on a remote machine
# Usage: ./scripts/setup-executor.sh [a|b|both]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
load_config

setup_device() {
    local host="$1" user="$2" port="$3" admin="$4" label="$5"
    echo "=== Setting up $label ($host) ==="

    # Ensure data directory exists
    echo "  Creating data directory..."
    run_on "$host" "$user" "mkdir -p $EXECUTOR_DATA_DIR"

    # Check if executor binary exists
    echo "  Checking executor binary..."
    if ! run_on "$host" "$user" "test -x $EXECUTOR_BIN"; then
        echo "  ERROR: Executor binary not found at $EXECUTOR_BIN on $host" >&2
        echo "  Build it first: cd \$AD4M_DIR && cargo build --release" >&2
        return 1
    fi

    # Kill any existing executor on the port
    echo "  Stopping any existing executor..."
    run_on "$host" "$user" "pkill -f 'ad4m-executor.*--port $port' || true"
    sleep 2

    # Clear test data for a fresh run
    echo "  Clearing test data directory..."
    run_on "$host" "$user" "rm -rf $EXECUTOR_DATA_DIR && mkdir -p $EXECUTOR_DATA_DIR"

    # Start executor in background
    echo "  Starting executor on port $port..."
    # shellcheck disable=SC2029
    run_on "$host" "$user" \
        "nohup $EXECUTOR_BIN \
            --port $port \
            --data-path $EXECUTOR_DATA_DIR \
            --admin-credential $admin \
            > $EXECUTOR_DATA_DIR/executor.log 2>&1 &"

    # Wait for it to be ready
    if wait_executor "$host" "$port" "$admin" 60; then
        echo "  ✅ $label ready"
    else
        echo "  ❌ $label failed to start. Check $EXECUTOR_DATA_DIR/executor.log" >&2
        return 1
    fi

    # Initialize agent
    init_agent "$host" "$port" "$admin"

    echo ""
}

target="${1:-both}"

case "$target" in
    a|A)
        setup_device "$DEVICE_A_HOST" "$DEVICE_A_USER" "$DEVICE_A_PORT" "$DEVICE_A_ADMIN" "Device A"
        ;;
    b|B)
        setup_device "$DEVICE_B_HOST" "$DEVICE_B_USER" "$DEVICE_B_PORT" "$DEVICE_B_ADMIN" "Device B"
        ;;
    both)
        setup_device "$DEVICE_A_HOST" "$DEVICE_A_USER" "$DEVICE_A_PORT" "$DEVICE_A_ADMIN" "Device A"
        setup_device "$DEVICE_B_HOST" "$DEVICE_B_USER" "$DEVICE_B_PORT" "$DEVICE_B_ADMIN" "Device B"
        ;;
    *)
        echo "Usage: $0 [a|b|both]" >&2
        exit 1
        ;;
esac

echo "=== Executor setup complete ==="
