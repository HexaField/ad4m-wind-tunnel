#!/usr/bin/env bash
# test-holochain.sh — Holochain Link Language integration test
# Infrastructure: None (uses public bootstrap/signal servers)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
source "$SCRIPT_DIR/../common.sh"
load_config

run_standard_tests "holochain" "${LANG_HOLOCHAIN:-}"
