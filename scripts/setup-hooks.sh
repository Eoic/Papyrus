#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$REPO_ROOT/.git/hooks"

cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
CLIENT_DIR="$REPO_ROOT/client"

STAGED_DART_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '^client/.*\.dart$' | sed 's|^client/||' || true)

if [ -z "$STAGED_DART_FILES" ]; then
    exit 0
fi

cd "$CLIENT_DIR"

FILES_LIST=$(echo "$STAGED_DART_FILES" | tr '\n' ' ')

dart format --set-exit-if-changed --output=none $FILES_LIST || {
    echo "Formatting issues found. Run 'dart format .' in client/ to fix."
    exit 1
}

dart analyze --fatal-infos || {
    echo "Analysis issues found. Fix the issues above before committing."
    exit 1
}
EOF

chmod +x "$HOOKS_DIR/pre-commit"
echo "Pre-commit hook installed."
