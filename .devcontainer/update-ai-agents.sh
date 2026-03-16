#!/bin/bash
set -uo pipefail

errors=0

echo "=== Updating Claude Code ==="
if claude update; then
    echo "Claude Code updated successfully"
else
    echo "Claude Code update failed (may already be at latest)"
    ((errors++))
fi

echo ""
echo "=== Updating GSD ==="
if npx --yes get-shit-done-cc@latest --claude --global; then
    echo "GSD updated successfully"
else
    echo "GSD update failed"
    ((errors++))
fi

echo ""
if [ "$errors" -gt 0 ]; then
    echo "$errors update(s) had issues. Check output above."
    exit 1
else
    echo "All AI agents updated successfully."
fi
