#!/usr/bin/env bash
# =============================================================================
# Content Pipeline — Skills Installer
# =============================================================================
# Installs all 17 content pipeline skills and their dependencies into any
# Claude Code project directory.
#
# Usage:
#   ./install.sh                    Install everything into current directory
#   ./install.sh --check            Check dependencies only, don't install
#   ./install.sh --skills-only      Only install skills (skip dep installation)
#   ./install.sh --config-only      Only create ~/.config/content-pipeline/.env
#   ./install.sh --output-dir PATH  Set a custom output directory
#   ./install.sh --help             Show this help
#
# Run from the target project directory, or pass the skills path:
#   cd ~/my-project && /path/to/skills/install.sh
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "  ${GREEN}✓${RESET} $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
err()  { echo -e "  ${RED}✗${RESET} $*"; }
info() { echo -e "  ${BLUE}→${RESET} $*"; }
header() { echo -e "\n${BOLD}$*${RESET}"; }

# ── Paths ─────────────────────────────────────────────────────────────────────
SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(pwd)"
HASHNODE_SCRIPTS="$SKILLS_DIR/hashnode/scripts"
REQUIREMENTS_TXT="$SKILLS_DIR/../requirements.txt"

# ── Flags ─────────────────────────────────────────────────────────────────────
CHECK_ONLY=false
SKILLS_ONLY=false
CONFIG_ONLY=false
CUSTOM_OUTPUT_DIR=""
SHOW_HELP=false

for arg in "$@"; do
  case "$arg" in
    --check)       CHECK_ONLY=true ;;
    --skills-only) SKILLS_ONLY=true ;;
    --config-only) CONFIG_ONLY=true ;;
    --help|-h)     SHOW_HELP=true ;;
    --output-dir=*) CUSTOM_OUTPUT_DIR="${arg#--output-dir=}" ;;
    --output-dir)  shift; CUSTOM_OUTPUT_DIR="${1:-}" ;;
  esac
done

# ── Help ──────────────────────────────────────────────────────────────────────
if $SHOW_HELP; then
  echo ""
  echo -e "${BOLD}Content Pipeline — Skills Installer${RESET}"
  echo ""
  echo "Usage:"
  echo "  $(basename "$0") [options]"
  echo ""
  echo "Options:"
  echo "  --check            Check all dependencies, report status, exit"
  echo "  --skills-only      Install skills only (skip pip/npm installs)"
  echo "  --config-only      Create ~/.config/content-pipeline/.env only"
  echo "  --output-dir PATH  Set output directory in config (default: \$PROJECT_DIR/output)"
  echo "  --help             Show this help"
  echo ""
  echo "Examples:"
  echo "  cd ~/my-project && /path/to/skills/install.sh"
  echo "  ./install.sh --check"
  echo "  ./install.sh --output-dir ~/content/output"
  echo ""
  exit 0
fi

# ── Header ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Content Pipeline — Skills Installer        ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""
info "Project dir : $PROJECT_DIR"
info "Skills dir  : $SKILLS_DIR"
echo ""

# ── OS Detection ─────────────────────────────────────────────────────────────
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ "$OSTYPE" == "linux"* ]]; then
  OS="linux"
fi

# ── Step 1: Dependency Check ──────────────────────────────────────────────────
header "Step 1: Checking dependencies"

DEPS_OK=true

# Claude Code (npx)
check_npx() {
  if command -v npx &>/dev/null; then
    ok "npx found: $(npx --version 2>/dev/null || echo 'ok')"
  else
    err "npx not found — install Node.js from https://nodejs.org"
    DEPS_OK=false
  fi
}

# Node.js version
check_node() {
  if command -v node &>/dev/null; then
    NODE_VER=$(node --version 2>/dev/null | sed 's/v//')
    NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
    if [[ "$NODE_MAJOR" -ge 16 ]]; then
      ok "Node.js v$NODE_VER (≥16 required)"
    else
      err "Node.js v$NODE_VER is too old — need ≥16. Upgrade at https://nodejs.org"
      DEPS_OK=false
    fi
  else
    err "Node.js not found — install from https://nodejs.org"
    DEPS_OK=false
  fi
}

# Python 3
check_python() {
  PYTHON_BIN=""
  for bin in python3 python; do
    if command -v "$bin" &>/dev/null; then
      PY_VER=$("$bin" --version 2>&1 | awk '{print $2}')
      PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
      PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
      if [[ "$PY_MAJOR" -eq 3 && "$PY_MINOR" -ge 8 ]]; then
        PYTHON_BIN="$bin"
        ok "Python $PY_VER (≥3.8 required) — $bin"
        break
      fi
    fi
  done
  if [[ -z "$PYTHON_BIN" ]]; then
    err "Python 3.8+ not found — install from https://python.org"
    DEPS_OK=false
  fi
}

# pip
check_pip() {
  PIP_BIN=""
  for bin in pip3 pip; do
    if command -v "$bin" &>/dev/null; then
      PIP_BIN="$bin"
      ok "pip found: $bin $(${bin} --version 2>/dev/null | awk '{print $2}')"
      break
    fi
  done
  if [[ -z "$PIP_BIN" ]]; then
    err "pip not found — run: python3 -m ensurepip --upgrade"
    DEPS_OK=false
  fi
}

# npm
check_npm() {
  if command -v npm &>/dev/null; then
    ok "npm found: $(npm --version)"
  else
    err "npm not found — install Node.js from https://nodejs.org"
    DEPS_OK=false
  fi
}

# yt-dlp
check_ytdlp() {
  if command -v yt-dlp &>/dev/null; then
    ok "yt-dlp found: $(yt-dlp --version 2>/dev/null)"
  else
    warn "yt-dlp not found — transcript fallback won't work"
    warn "Install: pip install yt-dlp  OR  brew install yt-dlp"
    # Not a hard failure — youtube-transcript-api is the primary
  fi
}

# Python packages
check_python_packages() {
  local all_ok=true
  for pkg_check in \
    "youtube_transcript_api:youtube-transcript-api" \
    "google.genai:google-genai" \
    "PIL:Pillow" \
    "dotenv:python-dotenv"; do
    local import_name="${pkg_check%%:*}"
    local pkg_name="${pkg_check##*:}"
    if ${PYTHON_BIN:-python3} -c "import $import_name" &>/dev/null; then
      ok "Python: $pkg_name"
    else
      warn "Python: $pkg_name not installed"
      all_ok=false
    fi
  done
  $all_ok || true  # warn only, installer will fix
}

# Node packages for hashnode
check_node_packages() {
  if [[ -d "$HASHNODE_SCRIPTS/node_modules" ]]; then
    local count
    count=$(ls "$HASHNODE_SCRIPTS/node_modules" | wc -l | tr -d ' ')
    ok "Hashnode node_modules ($count packages)"
  else
    warn "Hashnode node_modules not installed"
  fi
}

# Claude Code skills
check_skills() {
  local installed_count=0
  if [[ -d "$PROJECT_DIR/.agents/skills" ]]; then
    installed_count=$(ls "$PROJECT_DIR/.agents/skills" 2>/dev/null | wc -l | tr -d ' ')
  fi
  if [[ "$installed_count" -ge 17 ]]; then
    ok "Skills: $installed_count installed in .agents/skills/"
  elif [[ "$installed_count" -gt 0 ]]; then
    warn "Skills: only $installed_count of 17 installed"
  else
    warn "Skills: not installed (run without --check to install)"
  fi
}

# Config file
check_config() {
  local cfg="$HOME/.config/content-pipeline/.env"
  if [[ -f "$cfg" ]]; then
    ok "Config: $cfg"
    # Check each key
    for key in CONTENT_PIPELINE_OUTPUT GEMINI_API_KEY HASHNODE_API_KEY HASHNODE_PUBLICATION_ID; do
      local val
      val=$(grep "^${key}=" "$cfg" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
      if [[ -n "$val" && "$val" != *"your-"* && "$val" != *"here"* ]]; then
        if [[ "$key" == *"KEY"* || "$key" == *"ID"* ]]; then
          ok "  $key = ${val:0:8}..."
        else
          ok "  $key = $val"
        fi
      else
        warn "  $key not set (optional: needed for ${key//_/ } feature)"
      fi
    done
  else
    warn "Config: $cfg not found (run without --check to create)"
  fi
}

check_npx
check_node
check_python
check_pip
check_npm
check_ytdlp
echo ""
header "  Python packages:"
check_python_packages
echo ""
header "  Node packages:"
check_node_packages
echo ""
header "  Skills:"
check_skills
echo ""
header "  Configuration:"
check_config

if $CHECK_ONLY; then
  echo ""
  if $DEPS_OK; then
    echo -e "${GREEN}${BOLD}All system dependencies satisfied.${RESET}"
  else
    echo -e "${RED}${BOLD}Some dependencies are missing — see above.${RESET}"
    exit 1
  fi
  exit 0
fi

# ── Abort if hard deps missing ────────────────────────────────────────────────
if ! $DEPS_OK; then
  echo ""
  err "Hard dependencies are missing. Fix the errors above and re-run."
  exit 1
fi

echo ""

# ── Step 2: Python packages ───────────────────────────────────────────────────
if ! $SKILLS_ONLY && ! $CONFIG_ONLY; then
  header "Step 2: Installing Python packages"

  PIP="${PIP_BIN:-pip3}"
  REQ_FILE="$(realpath "$REQUIREMENTS_TXT" 2>/dev/null || echo "")"

  if [[ -f "$REQ_FILE" ]]; then
    info "Installing from $REQ_FILE"
    "$PIP" install -r "$REQ_FILE" --quiet && ok "All Python packages installed"
  else
    # Fallback: install individually
    warn "requirements.txt not found at $REQ_FILE — installing packages individually"
    for pkg in "youtube-transcript-api>=1.2.4" "yt-dlp" "google-genai>=1.0.0" "Pillow>=10.0.0" "python-dotenv"; do
      "$PIP" install "$pkg" --quiet && ok "$pkg"
    done
  fi
  echo ""
fi

# ── Step 3: Node.js packages (hashnode) ──────────────────────────────────────
if ! $SKILLS_ONLY && ! $CONFIG_ONLY; then
  header "Step 3: Installing Node.js packages (hashnode)"

  if [[ -d "$HASHNODE_SCRIPTS" ]]; then
    if [[ ! -d "$HASHNODE_SCRIPTS/node_modules" ]]; then
      info "Running npm install in $HASHNODE_SCRIPTS"
      (cd "$HASHNODE_SCRIPTS" && npm install --silent) && ok "Hashnode dependencies installed"
    else
      ok "Hashnode node_modules already present"
    fi
  else
    warn "Hashnode scripts directory not found — skipping"
  fi
  echo ""
fi

# ── Step 4: Install skills ────────────────────────────────────────────────────
if ! $CONFIG_ONLY; then
  header "Step 4: Installing skills"
  info "Source: $SKILLS_DIR"
  info "Target: $PROJECT_DIR/.agents/skills/"
  echo ""
  npx skills install "$SKILLS_DIR" --yes
  echo ""

  # Verify
  INSTALLED=$(ls "$PROJECT_DIR/.agents/skills" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$INSTALLED" -ge 17 ]]; then
    ok "$INSTALLED skills installed successfully"
  else
    warn "Expected 17 skills, got $INSTALLED — check output above"
  fi
  echo ""
fi

# ── Step 5: Config file ───────────────────────────────────────────────────────
if ! $SKILLS_ONLY; then
  header "Step 5: Configuring pipeline"

  CONFIG_DIR="$HOME/.config/content-pipeline"
  CONFIG_FILE="$CONFIG_DIR/.env"
  OUTPUT_DIR="${CUSTOM_OUTPUT_DIR:-$PROJECT_DIR/output}"

  mkdir -p "$CONFIG_DIR"
  mkdir -p "$OUTPUT_DIR"

  if [[ -f "$CONFIG_FILE" ]]; then
    ok "Config already exists: $CONFIG_FILE"
    info "Updating CONTENT_PIPELINE_OUTPUT to: $OUTPUT_DIR"
    # Update only the output dir line, leave API keys intact
    if grep -q "^CONTENT_PIPELINE_OUTPUT=" "$CONFIG_FILE"; then
      sed -i "s|^CONTENT_PIPELINE_OUTPUT=.*|CONTENT_PIPELINE_OUTPUT=$OUTPUT_DIR|" "$CONFIG_FILE"
    else
      echo "CONTENT_PIPELINE_OUTPUT=$OUTPUT_DIR" >> "$CONFIG_FILE"
    fi
  else
    info "Creating $CONFIG_FILE"
    cat > "$CONFIG_FILE" << EOF
# Content Pipeline Configuration
# Generated by install.sh on $(date +%Y-%m-%d)
#
# Edit this file to add your API keys.
# Keys are never stored in the repo — only in your home directory.

# ── Output directory ──────────────────────────────────────────────────────────
# Where all pipeline files are saved (transcripts, summaries, ideas, etc.)
CONTENT_PIPELINE_OUTPUT=$OUTPUT_DIR

# ── Obsidian vault ────────────────────────────────────────────────────────────
# Path to your Obsidian vault. Leave empty to skip Obsidian steps,
# or pass --skip-obsidian when running the pipeline.
OBSIDIAN_VAULT_PATH=

# ── Gemini API key ────────────────────────────────────────────────────────────
# Required for: /image-generator (AI image generation)
# NOT required for: /gemini-prompt-generator (generates prompts for manual use)
# Get your key: https://aistudio.google.com/app/apikey
# Note: Image generation requires billing enabled on your Google Cloud project.
GEMINI_API_KEY=

# ── Hashnode ─────────────────────────────────────────────────────────────────
# Required for: /hashnode (publishing drafts)
# API key:  https://hashnode.com/settings/developer → Personal Access Token
# Pub ID:   your dashboard URL: hashnode.com/dashboards/<ID>/general
HASHNODE_API_KEY=
HASHNODE_PUBLICATION_ID=
EOF
    ok "Created $CONFIG_FILE"
    echo ""
    warn "API keys are empty — edit the file to add them:"
    info "$CONFIG_FILE"
  fi

  ok "Output directory: $OUTPUT_DIR"
  echo ""
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║   Installation complete!                     ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${BOLD}Next steps:${RESET}"
echo ""

if [[ -f "$HOME/.config/content-pipeline/.env" ]]; then
  echo "  1. Add your API keys (optional — most skills work without them):"
  echo "     nano ~/.config/content-pipeline/.env"
  echo ""
fi

echo "  2. Open Claude Code in this project:"
echo "     claude ."
echo ""
echo "  3. Run the full pipeline:"
echo "     /youtube-pipeline https://youtube.com/watch?v=VIDEO_ID"
echo ""
echo "  4. Or run individual skills:"
echo "     /yt-transcript https://youtube.com/watch?v=VIDEO_ID"
echo ""
echo "  Verify everything is working:"
echo "     $(basename "$0") --check"
echo ""
