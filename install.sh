#!/usr/bin/env bash
set -euo pipefail

# Frontend QA Skills Installer
# Copies skill suite into a project's .claude/skills/frontend-qa/ or ~/.claude/skills/frontend-qa/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(cat "$SCRIPT_DIR/VERSION")"
ROLE="full"
INSTALL_MODE="project"
TARGET_DIR=""

usage() {
  cat <<EOF
Frontend QA Skills Installer v${VERSION}

Usage: ./install.sh [--role ROLE] [--global | TARGET_PROJECT_DIR]

Options:
  --global      Install to ~/.claude/ (available to all projects)
  --role ROLE   Install a subset of skills (default: full)
  --force       Force reinstall even if already installed

Roles:
  full          All 6 skills + shared references (default)
  diagnosis     qa-coordinator, page-component-mapper, ui-bug-investigator, css-layout-debugger
  remediation   component-fix-and-verify, regression-test-generator

Examples:
  ./install.sh /path/to/my-nextjs-app
  ./install.sh --role diagnosis /path/to/my-nextjs-app
  ./install.sh --global
  ./install.sh --role diagnosis --global
EOF
  exit 1
}

# Parse arguments
FORCE_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)
      ROLE="$2"
      shift 2
      ;;
    --global)
      INSTALL_MODE="global"
      shift
      ;;
    --force)
      FORCE_MODE=true
      shift
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

if [[ "$INSTALL_MODE" == "global" ]]; then
  if [[ -n "$TARGET_DIR" ]]; then
    echo "Error: --global and TARGET_PROJECT_DIR are mutually exclusive."
    exit 1
  fi
  BASE_DIR="$HOME/.claude"
else
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
  BASE_DIR="$TARGET_DIR/.claude"
fi

DEST="$BASE_DIR/skills/frontend-qa"
COMMANDS_DIR="$BASE_DIR/commands"

# Check if already installed
if [[ -d "$DEST" ]] && [[ "$FORCE_MODE" != true ]]; then
  echo "[SUCCESS] Frontend QA skills already installed at $DEST"
  echo ""
  echo "[INFO] To force reinstall: ./install.sh --force [same options]"
  exit 0
fi

echo "Installing frontend-qa-skills v${VERSION} (role: ${ROLE}) to:"
echo "  Skills:   $DEST"
echo "  Commands: $COMMANDS_DIR"
if [[ "$INSTALL_MODE" == "project" ]]; then
  CACHE_DIR="$BASE_DIR/qa-cache"
  echo "  Cache:    $CACHE_DIR"
fi
echo ""

# Create directories
mkdir -p "$DEST"
if [[ "$INSTALL_MODE" == "project" ]]; then
  mkdir -p "$CACHE_DIR/component-maps"
  mkdir -p "$CACHE_DIR/artifacts"
fi

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

# Copy commands to .claude/commands/ (where Claude Code discovers them)
if [[ -d "$SCRIPT_DIR/commands" ]]; then
  mkdir -p "$COMMANDS_DIR"
  for cmd in "$SCRIPT_DIR/commands/"*.md; do
    cp "$cmd" "$COMMANDS_DIR/"
  done
  echo "  Installed: commands -> $COMMANDS_DIR"
fi

# Add qa-cache to .gitignore if not already present (project installs only)
if [[ "$INSTALL_MODE" == "project" ]]; then
  GITIGNORE="$TARGET_DIR/.gitignore"
  if [[ -f "$GITIGNORE" ]]; then
    if ! grep -q ".claude/qa-cache" "$GITIGNORE" 2>/dev/null; then
      echo "" >> "$GITIGNORE"
      echo "# Frontend QA Skills cache" >> "$GITIGNORE"
      echo ".claude/qa-cache/" >> "$GITIGNORE"
      echo "  Updated .gitignore: added .claude/qa-cache/"
    fi
  fi
fi

echo ""
echo "Done. Installed ${ROLE} skills to $DEST"
echo ""
if [[ "$INSTALL_MODE" == "global" ]]; then
  echo "Note: Cache directories (.claude/qa-cache/) are created per-project on first use."
  echo ""
fi
echo "Usage:"
echo '  Describe a bug: "The /dashboard page sidebar overlaps on mobile"'
echo '  Or use a slash command: /qa, /map, /diagnose, /fix'
