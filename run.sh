#!/usr/bin/env bash
set -euo pipefail

# AD4M Wind Tunnel — Quick Run Script
# Usage:
#   ./run.sh                        # Build all branches and run all scenarios
#   ./run.sh --skip-build           # Use existing builds
#   ./run.sh --branch dev           # Only run against dev branch
#   ./run.sh --scenario s1          # Only run S1 scenario

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║            AD4M WIND TUNNEL — Runner                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Ensure dependencies
if [ ! -d "node_modules" ]; then
  echo "[setup] Installing dependencies..."
  npm install
fi

# Run
echo "[run] Starting wind tunnel..."
npx tsx src/main.ts "$@"

echo ""
echo "[done] Results available in ./results/"
echo "       Comparison: ./results/comparison.md"
