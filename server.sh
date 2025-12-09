#!/bin/bash

# LaTeX Build Script with XeLaTeX
# Usage: ./build.sh <file.tex> [once|clean|watch]

set -euo pipefail # Exit on error, undefined vars, pipe failures

# Configuration
BUILD_DIR="build"
DEFAULT_CMD="watch"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

cleanup_build_artifacts() {
  log_info "Cleaning auxiliary files in $BUILD_DIR..."
  find "$BUILD_DIR" -type f \
    \( -name "*.aux" \
    -o -name "*.log" \
    -o -name "*.out" \
    -o -name "*.fls" \
    -o -name "*.fdb_latexmk" \
    -o -name "*.synctex.gz" \
    -o -name "*.toc" \
    -o -name "*.lof" \
    -o -name "*.lot" \
    -o -name "*.bbl" \
    -o -name "*.blg" \
    -o -name "*.idx" \
    -o -name "*.ind" \
    -o -name "*.ilg" \
    -o -name "*.nav" \
    -o -name "*.snm" \
    -o -name "*.vrb" \) \
    -delete 2>/dev/null || true
  log_info "Cleanup complete. PDFs preserved."
}

# Validate inputs
if [[ $# -lt 1 ]]; then
  log_error "Usage: $0 <file.tex> [once|clean|watch]"
  exit 1
fi

FILE="$1"
CMD="${2:-$DEFAULT_CMD}"

# Check if file exists
if [[ ! -f "$FILE" ]]; then
  log_error "File not found: $FILE"
  exit 1
fi

# Ensure build directory exists
mkdir -p "$BUILD_DIR"

# Main logic
case "$CMD" in
clean)
  log_warn "Removing entire build directory: $BUILD_DIR"
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR"
  log_info "Build directory cleaned."
  ;;

cleanup)
  cleanup_build_artifacts
  ;;

once)
  log_info "Building once with XeLaTeX: $FILE"
  if latexmk \
    -xelatex \
    -interaction=nonstopmode \
    -halt-on-error \
    -output-directory="$BUILD_DIR" \
    "$FILE"; then
    log_info "Build successful: $BUILD_DIR/$(basename "$FILE" .tex).pdf"
    cleanup_build_artifacts
  else
    log_error "Build failed. Check logs in $BUILD_DIR"
    exit 1
  fi
  ;;

watch)
  log_info "Watching and building continuously with XeLaTeX: $FILE"
  log_info "Press Ctrl+C to stop..."
  latexmk \
    -xelatex \
    -interaction=nonstopmode \
    -pvc \
    -output-directory="$BUILD_DIR" \
    "$FILE"
  ;;

*)
  log_error "Unknown command: $CMD"
  log_info "Valid commands: once, clean, cleanup, watch (default)"
  exit 1
  ;;
esac
