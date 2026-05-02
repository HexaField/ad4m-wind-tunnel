#!/usr/bin/env bash
# common.sh — Shared functions for AD4M multi-device integration tests
# shellcheck disable=SC2034  # Variables are used by sourcing scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ─── Config ──────────────────────────────────────────────────────────────────

load_config() {
    local config_file="${CONFIG_FILE:-$REPO_DIR/config.env}"
    if [[ ! -f "$config_file" ]]; then
        echo "ERROR: Config file not found: $config_file" >&2
        echo "Copy config.example.env to config.env and edit it." >&2
        exit 1
    fi
    # shellcheck source=/dev/null
    source "$config_file"

    # Validate required vars
    local required=(
        DEVICE_A_HOST DEVICE_A_USER DEVICE_A_PORT DEVICE_A_ADMIN
        DEVICE_B_HOST DEVICE_B_USER DEVICE_B_PORT DEVICE_B_ADMIN
        EXECUTOR_BIN EXECUTOR_DATA_DIR SYNC_WAIT_SECONDS
    )
    for var in "${required[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo "ERROR: Required config variable $var is not set" >&2
            exit 1
        fi
    done
}

# ─── Results tracking ────────────────────────────────────────────────────────

RESULTS_DIR="$REPO_DIR/results"
CURRENT_LANGUAGE=""
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

init_results() {
    CURRENT_LANGUAGE="${1:?Language name required}"
    PASS_COUNT=0
    FAIL_COUNT=0
    SKIP_COUNT=0
    RESULTS_FILE="$RESULTS_DIR/${CURRENT_LANGUAGE}-$(date +%Y%m%dT%H%M%S).json"
    mkdir -p "$RESULTS_DIR"
    echo '{"language":"'"$CURRENT_LANGUAGE"'","tests":[],"started":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}' > "$RESULTS_FILE"
}

_record_result() {
    local status="$1" name="$2" message="${3:-}"
    local tmp
    tmp=$(mktemp)
    jq --arg s "$status" --arg n "$name" --arg m "$message" \
        '.tests += [{"name": $n, "status": $s, "message": $m, "timestamp": (now | todate)}]' \
        "$RESULTS_FILE" > "$tmp" && mv "$tmp" "$RESULTS_FILE"
}

pass() {
    local name="$1"
    ((PASS_COUNT++)) || true
    _record_result "PASS" "$name"
    echo "  ✅ PASS: $name"
}

fail() {
    local name="$1" message="${2:-}"
    ((FAIL_COUNT++)) || true
    _record_result "FAIL" "$name" "$message"
    echo "  ❌ FAIL: $name${message:+ — $message}"
}

skip() {
    local name="$1" reason="${2:-}"
    ((SKIP_COUNT++)) || true
    _record_result "SKIP" "$name" "$reason"
    echo "  ⏭️  SKIP: $name${reason:+ — $reason}"
}

finalize_results() {
    local tmp
    tmp=$(mktemp)
    jq --arg p "$PASS_COUNT" --arg f "$FAIL_COUNT" --arg s "$SKIP_COUNT" \
        '. + {"finished": (now | todate), "passed": ($p|tonumber), "failed": ($f|tonumber), "skipped": ($s|tonumber)}' \
        "$RESULTS_FILE" > "$tmp" && mv "$tmp" "$RESULTS_FILE"
    echo ""
    echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed, $SKIP_COUNT skipped"
    echo "Written to: $RESULTS_FILE"
    return "$FAIL_COUNT"
}

# ─── SSH ─────────────────────────────────────────────────────────────────────

run_on() {
    local host="$1" user="$2"
    shift 2
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$user@$host" "$@"
}

# ─── GraphQL ─────────────────────────────────────────────────────────────────

gql() {
    local host="$1" port="$2" token="$3" query="$4" vars="${5:-"{}"}"
    local payload
    payload=$(jq -n --arg q "$query" --argjson v "$vars" '{"query": $q, "variables": $v}')
    curl -sf -X POST "http://$host:$port/graphql" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -d "$payload"
}

gql_field() {
    # Execute GraphQL and extract a specific jq path
    local host="$1" port="$2" token="$3" query="$4" jq_path="$5" vars="${6:-"{}"}"
    local result
    result=$(gql "$host" "$port" "$token" "$query" "$vars")
    echo "$result" | jq -r "$jq_path"
}

# ─── Executor lifecycle ─────────────────────────────────────────────────────

wait_executor() {
    local host="$1" port="$2" token="$3" timeout="${4:-30}"
    echo "  Waiting for executor at $host:$port..."
    for i in $(seq 1 "$timeout"); do
        if curl -sf "http://$host:$port/api/v1/agent/status" \
            -H "Authorization: Bearer $token" >/dev/null 2>&1; then
            echo "  Executor ready after ${i}s"
            return 0
        fi
        sleep 1
    done
    echo "  ERROR: Executor at $host:$port not ready after ${timeout}s" >&2
    return 1
}

init_agent() {
    local host="$1" port="$2" token="$3"
    echo "  Initializing agent on $host:$port..."
    local status
    status=$(gql_field "$host" "$port" "$token" \
        'query { agentStatus { isInitialized did } }' \
        '.data.agentStatus.isInitialized')

    if [[ "$status" == "true" ]]; then
        echo "  Agent already initialized"
        return 0
    fi

    gql "$host" "$port" "$token" \
        'mutation { runtimeCreateUser(email: "dev@test.com", password: "test123") }' > /dev/null 2>&1 || true
    gql "$host" "$port" "$token" \
        'mutation { runtimeLoginUser(email: "dev@test.com", password: "test123") }' > /dev/null 2>&1 || true

    echo "  Agent initialized"
}

# ─── Language operations ─────────────────────────────────────────────────────

install_language() {
    local host="$1" port="$2" token="$3" lang_address="$4"
    echo "  Installing language $lang_address on $host..."
    local result
    # shellcheck disable=SC2016
    result=$(gql "$host" "$port" "$token" \
        'mutation($addr: String!) { languageInstall(address: $addr) { address } }' \
        "{\"addr\": \"$lang_address\"}")
    echo "$result" | jq -r '.data.languageInstall.address // empty'
}

# ─── Perspective operations ──────────────────────────────────────────────────

create_perspective() {
    local host="$1" port="$2" token="$3" name="$4"
    echo "  Creating perspective '$name' on $host..."
    gql_field "$host" "$port" "$token" \
        "mutation { perspectiveAdd(name: \"$name\") { uuid } }" \
        '.data.perspectiveAdd.uuid'
}

remove_perspective() {
    local host="$1" port="$2" token="$3" uuid="$4"
    gql "$host" "$port" "$token" \
        "mutation { perspectiveRemove(uuid: \"$uuid\") }" > /dev/null 2>&1 || true
}

# ─── Neighbourhood operations ────────────────────────────────────────────────

create_neighbourhood() {
    local host="$1" port="$2" token="$3" perspective_uuid="$4" lang_address="$5"
    echo "  Creating neighbourhood on $host (perspective: $perspective_uuid)..."
    gql_field "$host" "$port" "$token" \
        "mutation { neighbourhoodCreate(perspectiveUuid: \"$perspective_uuid\", linkLanguage: \"$lang_address\", meta: { links: [] }) }" \
        '.data.neighbourhoodCreate // empty'
}

join_neighbourhood() {
    local host="$1" port="$2" token="$3" neighbourhood_url="$4"
    echo "  Joining neighbourhood on $host..."
    gql_field "$host" "$port" "$token" \
        "mutation { neighbourhoodJoinFromUrl(url: \"$neighbourhood_url\") { uuid } }" \
        '.data.neighbourhoodJoinFromUrl.uuid'
}

# ─── Link operations ─────────────────────────────────────────────────────────

add_link() {
    local host="$1" port="$2" token="$3" uuid="$4" source="$5" predicate="$6" target="$7"
    gql "$host" "$port" "$token" \
        "mutation { perspectiveAddLink(uuid: \"$uuid\", link: { source: \"$source\", predicate: \"$predicate\", target: \"$target\" }) { author timestamp data { source predicate target } } }" \
        > /dev/null
}

remove_link() {
    local host="$1" port="$2" token="$3" uuid="$4" source="$5" predicate="$6" target="$7"
    gql "$host" "$port" "$token" \
        "mutation { perspectiveRemoveLink(uuid: \"$uuid\", link: { source: \"$source\", predicate: \"$predicate\", target: \"$target\" }) }" \
        > /dev/null
}

get_links() {
    local host="$1" port="$2" token="$3" uuid="$4"
    gql_field "$host" "$port" "$token" \
        "query { perspective(uuid: \"$uuid\") { links { data { source predicate target } } } }" \
        '.data.perspective.links'
}

count_links() {
    local host="$1" port="$2" token="$3" uuid="$4"
    get_links "$host" "$port" "$token" "$uuid" | jq 'length'
}

# ─── Assertions ──────────────────────────────────────────────────────────────

assert_link_exists() {
    local host="$1" port="$2" token="$3" uuid="$4" source="$5" predicate="$6" target="$7"
    local links
    links=$(get_links "$host" "$port" "$token" "$uuid")
    echo "$links" | jq -e \
        --arg s "$source" --arg p "$predicate" --arg t "$target" \
        '[.[] | select(.data.source == $s and .data.predicate == $p and .data.target == $t)] | length > 0' \
        > /dev/null 2>&1
}

assert_link_gone() {
    local host="$1" port="$2" token="$3" uuid="$4" source="$5" predicate="$6" target="$7"
    local links
    links=$(get_links "$host" "$port" "$token" "$uuid")
    echo "$links" | jq -e \
        --arg s "$source" --arg p "$predicate" --arg t "$target" \
        '[.[] | select(.data.source == $s and .data.predicate == $p and .data.target == $t)] | length == 0' \
        > /dev/null 2>&1
}

wait_and_assert_link() {
    local host="$1" port="$2" token="$3" uuid="$4" source="$5" predicate="$6" target="$7"
    local timeout="${8:-$SYNC_WAIT_SECONDS}"
    for _ in $(seq 1 "$timeout"); do
        if assert_link_exists "$host" "$port" "$token" "$uuid" "$source" "$predicate" "$target" 2>/dev/null; then
            return 0
        fi
        sleep 1
    done
    return 1
}

wait_and_assert_link_gone() {
    local host="$1" port="$2" token="$3" uuid="$4" source="$5" predicate="$6" target="$7"
    local timeout="${8:-$SYNC_WAIT_SECONDS}"
    for _ in $(seq 1 "$timeout"); do
        if assert_link_gone "$host" "$port" "$token" "$uuid" "$source" "$predicate" "$target" 2>/dev/null; then
            return 0
        fi
        sleep 1
    done
    return 1
}

# ─── Infrastructure helpers ──────────────────────────────────────────────────

start_infra() {
    local compose_file="$1" host="$2" user="$3"
    echo "  Starting infrastructure from $compose_file on $host..."
    local filename
    filename=$(basename "$compose_file")
    # Copy compose file to remote and start
    scp -o StrictHostKeyChecking=no "$REPO_DIR/infra/$filename" "$user@$host:/tmp/$filename"
    run_on "$host" "$user" "cd /tmp && docker compose -f $filename up -d"
}

stop_infra() {
    local compose_file="$1" host="$2" user="$3"
    local filename
    filename=$(basename "$compose_file")
    echo "  Stopping infrastructure from $filename on $host..."
    run_on "$host" "$user" "cd /tmp && docker compose -f $filename down -v" 2>/dev/null || true
}

wait_http() {
    local url="$1" timeout="${2:-30}"
    echo "  Waiting for $url..."
    for i in $(seq 1 "$timeout"); do
        if curl -sf "$url" > /dev/null 2>&1; then
            echo "  $url ready after ${i}s"
            return 0
        fi
        sleep 1
    done
    echo "  ERROR: $url not ready after ${timeout}s" >&2
    return 1
}

wait_ws() {
    # Simple WebSocket readiness check — just verify the port is open
    local host="$1" port="$2" timeout="${3:-30}"
    echo "  Waiting for WebSocket at $host:$port..."
    for i in $(seq 1 "$timeout"); do
        if nc -z -w1 "$host" "$port" 2>/dev/null; then
            echo "  WebSocket port ready after ${i}s"
            return 0
        fi
        sleep 1
    done
    echo "  ERROR: WebSocket at $host:$port not ready after ${timeout}s" >&2
    return 1
}

# ─── Standard test flow ─────────────────────────────────────────────────────

# Runs the standard 4-test suite for a given language.
# Args: language_name lang_address [setup_fn] [teardown_fn]
# setup_fn and teardown_fn are optional function names for infra lifecycle.
run_standard_tests() {
    local language="$1" lang_address="$2"
    local setup_fn="${3:-}" teardown_fn="${4:-}"

    init_results "$language"
    echo "=== Testing $language Link Language ==="
    echo ""

    # Check language address
    if [[ -z "$lang_address" ]]; then
        skip "all" "Language address not configured (set LANG_${language^^} in config.env)"
        finalize_results || true
        return 0
    fi

    # Setup infrastructure if needed
    if [[ -n "$setup_fn" ]]; then
        if ! "$setup_fn"; then
            fail "infrastructure" "Failed to start infrastructure"
            finalize_results || true
            return 1
        fi
    fi

    # Install language on both devices
    echo "Installing language on both devices..."
    install_language "$DEVICE_A_HOST" "$DEVICE_A_PORT" "$DEVICE_A_ADMIN" "$lang_address" || true
    install_language "$DEVICE_B_HOST" "$DEVICE_B_PORT" "$DEVICE_B_ADMIN" "$lang_address" || true

    # Create neighbourhood on Device A
    local perspective_a neighbourhood_url perspective_b
    perspective_a=$(create_perspective "$DEVICE_A_HOST" "$DEVICE_A_PORT" "$DEVICE_A_ADMIN" "test-$language")
    neighbourhood_url=$(create_neighbourhood "$DEVICE_A_HOST" "$DEVICE_A_PORT" "$DEVICE_A_ADMIN" "$perspective_a" "$lang_address")

    if [[ -z "$neighbourhood_url" ]]; then
        fail "neighbourhood-create" "Failed to create neighbourhood"
        finalize_results || true
        [[ -n "$teardown_fn" ]] && "$teardown_fn"
        return 1
    fi

    # Join on Device B
    perspective_b=$(join_neighbourhood "$DEVICE_B_HOST" "$DEVICE_B_PORT" "$DEVICE_B_ADMIN" "$neighbourhood_url")

    if [[ -z "$perspective_b" ]]; then
        fail "neighbourhood-join" "Failed to join neighbourhood"
        remove_perspective "$DEVICE_A_HOST" "$DEVICE_A_PORT" "$DEVICE_A_ADMIN" "$perspective_a"
        finalize_results || true
        [[ -n "$teardown_fn" ]] && "$teardown_fn"
        return 1
    fi

    # Allow initial sync to settle
    sleep 2

    # Test 1: A→B sync
    echo ""
    echo "Test 1: A→B link sync"
    add_link "$DEVICE_A_HOST" "$DEVICE_A_PORT" "$DEVICE_A_ADMIN" "$perspective_a" \
        "test://source-1" "test://predicate" "test://target-1"
    if wait_and_assert_link "$DEVICE_B_HOST" "$DEVICE_B_PORT" "$DEVICE_B_ADMIN" "$perspective_b" \
        "test://source-1" "test://predicate" "test://target-1"; then
        pass "A→B sync"
    else
        fail "A→B sync" "Link not found on Device B within ${SYNC_WAIT_SECONDS}s"
    fi

    # Test 2: B→A sync
    echo "Test 2: B→A link sync"
    add_link "$DEVICE_B_HOST" "$DEVICE_B_PORT" "$DEVICE_B_ADMIN" "$perspective_b" \
        "test://source-2" "test://predicate" "test://target-2"
    if wait_and_assert_link "$DEVICE_A_HOST" "$DEVICE_A_PORT" "$DEVICE_A_ADMIN" "$perspective_a" \
        "test://source-2" "test://predicate" "test://target-2"; then
        pass "B→A sync"
    else
        fail "B→A sync" "Link not found on Device A within ${SYNC_WAIT_SECONDS}s"
    fi

    # Test 3: Removal sync A→B
    echo "Test 3: Removal sync A→B"
    remove_link "$DEVICE_A_HOST" "$DEVICE_A_PORT" "$DEVICE_A_ADMIN" "$perspective_a" \
        "test://source-1" "test://predicate" "test://target-1"
    if wait_and_assert_link_gone "$DEVICE_B_HOST" "$DEVICE_B_PORT" "$DEVICE_B_ADMIN" "$perspective_b" \
        "test://source-1" "test://predicate" "test://target-1"; then
        pass "Removal sync"
    else
        fail "Removal sync" "Removed link still present on Device B after ${SYNC_WAIT_SECONDS}s"
    fi

    # Test 4: Batch sync (10 links)
    echo "Test 4: Batch sync (10 links)"
    for i in $(seq 1 10); do
        add_link "$DEVICE_A_HOST" "$DEVICE_A_PORT" "$DEVICE_A_ADMIN" "$perspective_a" \
            "test://batch-$i" "test://batch-predicate" "test://batch-target-$i"
    done
    sleep "$SYNC_WAIT_SECONDS"
    local link_count
    link_count=$(count_links "$DEVICE_B_HOST" "$DEVICE_B_PORT" "$DEVICE_B_ADMIN" "$perspective_b")
    # Expect at least 11 links: 1 remaining from test 2 + 10 batch
    if [[ "$link_count" -ge 11 ]]; then
        pass "Batch sync ($link_count links)"
    else
        fail "Batch sync" "Expected ≥11 links, got $link_count"
    fi

    # Cleanup perspectives
    echo ""
    echo "Cleaning up perspectives..."
    remove_perspective "$DEVICE_A_HOST" "$DEVICE_A_PORT" "$DEVICE_A_ADMIN" "$perspective_a"
    remove_perspective "$DEVICE_B_HOST" "$DEVICE_B_PORT" "$DEVICE_B_ADMIN" "$perspective_b"

    # Teardown infrastructure if needed
    if [[ -n "$teardown_fn" ]]; then
        "$teardown_fn"
    fi

    echo ""
    echo "=== $language tests complete ==="
    finalize_results || true
}
