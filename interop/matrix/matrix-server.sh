#!/usr/bin/env bash
# matrix-server.sh — Spin up Matrix server (Conduit) + Element Web for testing
#
# Manages Docker containers for a Matrix homeserver and optional Element Web
# client. Creates test users, a room, and outputs connection details as a
# sourceable env file.
#
# Usage:
#   ./matrix-server.sh start [options]
#   ./matrix-server.sh stop
#   ./matrix-server.sh status
#
# See --help for full options.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-matrix.sh"

# ═══════════════════════════════════════════════════════════════════════════════
# Defaults
# ═══════════════════════════════════════════════════════════════════════════════

CONDUIT_PORT="${CONDUIT_PORT:-6167}"
ELEMENT_PORT="${ELEMENT_PORT:-8088}"
SERVER_NAME="${SERVER_NAME:-ad4m-test.local}"
BRIDGE_USER="${BRIDGE_USER:-bridge_bot}"
BRIDGE_PASS="${BRIDGE_PASS:-bridgepass123}"
HUMAN_USER="${HUMAN_USER:-human_test}"
HUMAN_PASS="${HUMAN_PASS:-humanpass123}"
ROOM_NAME="${ROOM_NAME:-Flux Bridge Room}"
ROOM_ALIAS="${ROOM_ALIAS:-flux-bridge}"
ENV_FILE="${ENV_FILE:-/tmp/matrix-bridge-env}"
NO_ELEMENT=false

CONDUIT_CONTAINER="matrix-bridge-conduit"
ELEMENT_CONTAINER="matrix-bridge-element"
CONDUIT_IMAGE="matrixconduit/matrix-conduit:latest"
ELEMENT_IMAGE="vectorim/element-web:latest"

# ═══════════════════════════════════════════════════════════════════════════════
# Help
# ═══════════════════════════════════════════════════════════════════════════════

show_help() {
    cat <<'EOF'
matrix-server.sh — Matrix (Conduit) + Element Web Infrastructure Manager

Usage:
  matrix-server.sh start [options]    Start Conduit + Element Web, create users/room
  matrix-server.sh stop               Stop and remove containers
  matrix-server.sh status             Show running container status

Start Options:
  --conduit-port PORT     Conduit port (default: 6167)
  --element-port PORT     Element Web port (default: 8088)
  --no-element            Skip Element Web
  --server-name NAME      Matrix server name (default: ad4m-test.local)
  --bridge-user USER      Bridge bot username (default: bridge_bot)
  --bridge-pass PASS      Bridge bot password (default: bridgepass123)
  --human-user USER       Human test user (default: human_test)
  --human-pass PASS       Human test password (default: humanpass123)
  --room-name NAME        Room display name (default: "Flux Bridge Room")
  --room-alias ALIAS      Room alias (default: flux-bridge)
  --env-file PATH         Output env file (default: /tmp/matrix-bridge-env)
  -h, --help              Show this help

Output:
  Writes a sourceable env file with MATRIX_URL, ROOM_ID, tokens, etc.

Examples:
  ./matrix-server.sh start
  ./matrix-server.sh start --conduit-port 7167 --no-element
  source /tmp/matrix-bridge-env && echo $MATRIX_ROOM_ID
  ./matrix-server.sh stop
EOF
    exit 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# Parse Arguments
# ═══════════════════════════════════════════════════════════════════════════════

ACTION="${1:-}"
[[ -n "$ACTION" ]] && shift || { show_help; }

case "$ACTION" in
    start|stop|status) ;;
    -h|--help) show_help ;;
    *) error "Unknown action: $ACTION (use start, stop, or status)"; exit 1 ;;
esac

while [[ $# -gt 0 ]]; do
    case "$1" in
        --conduit-port) CONDUIT_PORT="$2"; shift 2 ;;
        --element-port) ELEMENT_PORT="$2"; shift 2 ;;
        --no-element)   NO_ELEMENT=true; shift ;;
        --server-name)  SERVER_NAME="$2"; shift 2 ;;
        --bridge-user)  BRIDGE_USER="$2"; shift 2 ;;
        --bridge-pass)  BRIDGE_PASS="$2"; shift 2 ;;
        --human-user)   HUMAN_USER="$2"; shift 2 ;;
        --human-pass)   HUMAN_PASS="$2"; shift 2 ;;
        --room-name)    ROOM_NAME="$2"; shift 2 ;;
        --room-alias)   ROOM_ALIAS="$2"; shift 2 ;;
        --env-file)     ENV_FILE="$2"; shift 2 ;;
        -h|--help)      show_help ;;
        *) error "Unknown option: $1"; exit 1 ;;
    esac
done

MATRIX_URL="http://127.0.0.1:${CONDUIT_PORT}"

# ═══════════════════════════════════════════════════════════════════════════════
# Commands
# ═══════════════════════════════════════════════════════════════════════════════

do_status() {
    header "Matrix Server Status"
    local conduit_status element_status
    conduit_status=$(docker inspect -f '{{.State.Status}}' "$CONDUIT_CONTAINER" 2>/dev/null) || conduit_status="not found"
    element_status=$(docker inspect -f '{{.State.Status}}' "$ELEMENT_CONTAINER" 2>/dev/null) || element_status="not found"

    echo -e "  Conduit ($CONDUIT_CONTAINER): ${conduit_status}"
    echo -e "  Element ($ELEMENT_CONTAINER): ${element_status}"

    if [[ "$conduit_status" == "running" ]]; then
        local port
        port=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "6167/tcp") 0).HostPort}}' "$CONDUIT_CONTAINER" 2>/dev/null) || port="?"
        echo -e "  Conduit URL: http://127.0.0.1:${port}"
    fi
    if [[ -f "$ENV_FILE" ]]; then
        echo -e "  Env file: $ENV_FILE"
    fi
}

do_stop() {
    header "Stopping Matrix Server"
    step "Removing containers..."
    docker rm -f "$CONDUIT_CONTAINER" 2>/dev/null && info "Stopped $CONDUIT_CONTAINER" || info "$CONDUIT_CONTAINER not running"
    docker rm -f "$ELEMENT_CONTAINER" 2>/dev/null && info "Stopped $ELEMENT_CONTAINER" || info "$ELEMENT_CONTAINER not running"
    if [[ -f "$ENV_FILE" ]]; then
        rm -f "$ENV_FILE"
        info "Removed env file: $ENV_FILE"
    fi
    success "Matrix infrastructure stopped"
}

do_start() {
    header "Starting Matrix Server"

    check_matrix_deps

    # ─── Start Conduit ────────────────────────────────────────────────────

    step "Starting Conduit on port $CONDUIT_PORT..."

    # Create temp config
    local config_dir
    config_dir=$(mktemp -d /tmp/matrix-server-config-XXXXXX)
    cat > "$config_dir/conduit.toml" <<TOMLEOF
[global]
server_name = "$SERVER_NAME"
port = 6167
address = "0.0.0.0"
database_backend = "rocksdb"
database_path = "/var/lib/matrix-conduit/"
allow_registration = true
allow_federation = false
max_request_size = 20_000_000
trusted_servers = ["matrix.org"]
allow_room_creation = true
TOMLEOF

    docker rm -f "$CONDUIT_CONTAINER" 2>/dev/null || true

    docker run -d \
        --name "$CONDUIT_CONTAINER" \
        -p "${CONDUIT_PORT}:6167" \
        -v "$config_dir/conduit.toml:/etc/conduit/conduit.toml:ro" \
        -e CONDUIT_CONFIG="/etc/conduit/conduit.toml" \
        "$CONDUIT_IMAGE" >/dev/null 2>&1

    if wait_for_url "${MATRIX_URL}/_matrix/client/versions" "Conduit" 30; then
        local version
        version=$(curl -sf "${MATRIX_URL}/_matrix/client/versions" | jq -r '.versions[-1] // "unknown"')
        pass "conduit-start" "Ready at $MATRIX_URL (spec $version)"
    else
        fail "conduit-start" "Not ready after 30s"
        docker logs "$CONDUIT_CONTAINER" 2>&1 | tail -10
        print_summary "Matrix Server" || exit 1
    fi

    # ─── Start Element Web (optional) ─────────────────────────────────────

    local element_url=""
    if [[ "$NO_ELEMENT" != "true" ]]; then
        step "Starting Element Web on port $ELEMENT_PORT..."
        docker rm -f "$ELEMENT_CONTAINER" 2>/dev/null || true

        docker run -d \
            --name "$ELEMENT_CONTAINER" \
            -p "${ELEMENT_PORT}:80" \
            "$ELEMENT_IMAGE" >/dev/null 2>&1

        if wait_for_url "http://127.0.0.1:${ELEMENT_PORT}" "Element Web" 15; then
            element_url="http://127.0.0.1:${ELEMENT_PORT}"
            pass "element-start" "Ready at $element_url"
        else
            warn "Element Web did not start — continuing without it"
        fi
    else
        info "Skipping Element Web (--no-element)"
    fi

    # ─── Create users ────────────────────────────────────────────────────

    step "Creating bridge bot user (@${BRIDGE_USER}:${SERVER_NAME})..."
    local bridge_token
    bridge_token=$(matrix_register_or_login "$MATRIX_URL" "$BRIDGE_USER" "$BRIDGE_PASS")
    if [[ -n "$bridge_token" ]]; then
        pass "bridge-user" "@${BRIDGE_USER}:${SERVER_NAME}"
    else
        fail "bridge-user" "Failed to register/login bridge bot"
        print_summary "Matrix Server" || exit 1
    fi

    step "Creating human test user (@${HUMAN_USER}:${SERVER_NAME})..."
    local human_token
    human_token=$(matrix_register_or_login "$MATRIX_URL" "$HUMAN_USER" "$HUMAN_PASS")
    if [[ -n "$human_token" ]]; then
        pass "human-user" "@${HUMAN_USER}:${SERVER_NAME}"
    else
        fail "human-user" "Failed to register/login human user"
        print_summary "Matrix Server" || exit 1
    fi

    # ─── Create room ─────────────────────────────────────────────────────

    step "Creating room '$ROOM_NAME' (#${ROOM_ALIAS}:${SERVER_NAME})..."
    local room_id
    room_id=$(matrix_create_room "$MATRIX_URL" "$bridge_token" "$ROOM_NAME" "$ROOM_ALIAS")

    if [[ -n "$room_id" ]]; then
        pass "room-create" "Room: $room_id"
    else
        fail "room-create" "Failed to create or find room"
        print_summary "Matrix Server" || exit 1
    fi

    # Human joins
    matrix_join_room "$MATRIX_URL" "$human_token" "$room_id"
    info "Human user joined room"

    # ─── Write env file ──────────────────────────────────────────────────

    cat > "$ENV_FILE" <<ENVEOF
# Matrix bridge environment — generated by matrix-server.sh
# Source this file: source $ENV_FILE
MATRIX_URL=$MATRIX_URL
MATRIX_ROOM_ID=$room_id
BRIDGE_TOKEN=$bridge_token
HUMAN_TOKEN=$human_token
BRIDGE_USER_ID=@${BRIDGE_USER}:${SERVER_NAME}
HUMAN_USER_ID=@${HUMAN_USER}:${SERVER_NAME}
CONDUIT_PORT=$CONDUIT_PORT
SERVER_NAME=$SERVER_NAME
ENVEOF

    if [[ -n "$element_url" ]]; then
        echo "ELEMENT_URL=$element_url" >> "$ENV_FILE"
    fi

    success "Environment written to $ENV_FILE"
    info "Source it with: source $ENV_FILE"

    # ─── Summary ─────────────────────────────────────────────────────────

    echo ""
    info "Matrix URL:     $MATRIX_URL"
    info "Room ID:        $room_id"
    info "Bridge user:    @${BRIDGE_USER}:${SERVER_NAME}"
    info "Human user:     @${HUMAN_USER}:${SERVER_NAME}"
    [[ -n "$element_url" ]] && info "Element Web:    $element_url"
    echo ""

    print_summary "Matrix Server" || exit 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dispatch
# ═══════════════════════════════════════════════════════════════════════════════

case "$ACTION" in
    start)  do_start ;;
    stop)   do_stop ;;
    status) do_status ;;
esac
