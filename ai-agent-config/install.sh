#!/bin/bash
set -euo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SRC_DIR/install-ai-agent-config.sh"
bash "$SRC_DIR/install-delegation-hooks.sh"
