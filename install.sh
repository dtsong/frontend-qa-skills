#!/usr/bin/env bash
set -euo pipefail

# Frontend QA Skills Installer
# Copies skill suite into a target Next.js project's .claude/skills/frontend-qa/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(cat "$SCRIPT_DIR/VERSION")"
ROLE="full"
TARGET_DIR=""

usage() {
  cat <<EOF
Frontend QA Skills Installer v${VERSION}

Usage: ./install.sh [--role ROLE] TARGET_PROJECT_DIR

Roles:
  full          All 6 skills + shared references (default)
  diagnosis     qa-coordinator, page-component-mapper, ui-bug-investigator, css-layout-debugger
  remediation   component-fix-and-verify, regression-test-generator

Examples:
  ./install.sh /path/to/my-nextjs-app
  ./install.sh --role diagnosis /path/to/my-nextjs-app
EOF
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)
      ROLE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

if [[ -z "$TARGET_DIR" ]]; then
  echo "Error: No target project directory specified."
  usage
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: Target directory does not exist: $TARGET_DIR"
  exit 1
fi

# Validate target is a Next.js project
if [[ ! -f "$TARGET_DIR/package.json" ]]; then
  echo "Error: No package.json found in $TARGET_DIR. Is this a Node.js project?"
  exit 1
fi

if ! grep -q '"next"' "$TARGET_DIR/package.json" 2>/dev/null; then
  echo "Warning: 'next' not found in package.json dependencies. This suite is designed for Next.js projects."
  read -r -p "Continue anyway? [y/N] " response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

DEST="$TARGET_DIR/.claude/skills/frontend-qa"
CACHE_DIR="$TARGET_DIR/.claude/qa-cache"

echo "Installing frontend-qa-skills v${VERSION} (role: ${ROLE}) to:"
echo "  Skills: $DEST"
echo "  Cache:  $CACHE_DIR"
echo ""

# Create directories
mkdir -p "$DEST"
mkdir -p "$CACHE_DIR/component-maps"
mkdir -p "$CACHE_DIR/artifacts"

# Define skill sets per role
SKILLS_FULL="qa-coordinator page-component-mapper ui-bug-investigator css-layout-debugger component-fix-and-verify regression-test-generator"
SKILLS_DIAGNOSIS="qa-coordinator page-component-mapper ui-bug-investigator css-layout-debugger"
SKILLS_REMEDIATION="component-fix-and-verify regression-test-generator"

case "$ROLE" in
  full)
    SKILLS="$SKILLS_FULL"
    ;;
  diagnosis)
    SKILLS="$SKILLS_DIAGNOSIS"
    ;;
  remediation)
    SKILLS="$SKILLS_REMEDIATION"
    ;;
  *)
    echo "Error: Unknown role '$ROLE'. Valid roles: full, diagnosis, remediation"
    exit 1
    ;;
esac

# Copy skills
for skill in $SKILLS; do
  if [[ -d "$SCRIPT_DIR/$skill" ]]; then
    cp -r "$SCRIPT_DIR/$skill" "$DEST/"
    echo "  Installed: $skill"
  else
    echo "  Warning: Skill directory not found: $skill"
  fi
done

# Always copy shared references
if [[ -d "$SCRIPT_DIR/shared-references" ]]; then
  cp -r "$SCRIPT_DIR/shared-references" "$DEST/"
  echo "  Installed: shared-references"
fi

# Copy commands
if [[ -d "$SCRIPT_DIR/commands" ]]; then
  cp -r "$SCRIPT_DIR/commands" "$DEST/"
  echo "  Installed: commands"
fi

# Add qa-cache to .gitignore if not already present
GITIGNORE="$TARGET_DIR/.gitignore"
if [[ -f "$GITIGNORE" ]]; then
  if ! grep -q ".claude/qa-cache" "$GITIGNORE" 2>/dev/null; then
    echo "" >> "$GITIGNORE"
    echo "# Frontend QA Skills cache" >> "$GITIGNORE"
    echo ".claude/qa-cache/" >> "$GITIGNORE"
    echo "  Updated .gitignore: added .claude/qa-cache/"
  fi
fi

echo ""
echo "Done. Installed ${ROLE} skills to $DEST"
echo ""
echo "Usage:"
echo '  Describe a bug: "The /dashboard page sidebar overlaps on mobile"'
echo '  Or use a slash command: /qa, /map, /diagnose, /fix'
