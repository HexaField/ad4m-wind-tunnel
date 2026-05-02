#!/usr/bin/env bash
# test-activitypub.sh — ActivityPub Link Language integration test
# Infrastructure: None required (uses federation between AD4M executors' built-in AP servers)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
source "$SCRIPT_DIR/../common.sh"
load_config

run_standard_tests "activitypub" "${LANG_ACTIVITYPUB:-}"
