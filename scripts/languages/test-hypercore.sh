#!/usr/bin/env bash
# test-hypercore.sh — Hypercore Link Language integration test
# Infrastructure: None (uses Hyperswarm DHT — fully P2P, zero infra)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
source "$SCRIPT_DIR/../common.sh"
load_config

run_standard_tests "hypercore" "${LANG_HYPERCORE:-}"
