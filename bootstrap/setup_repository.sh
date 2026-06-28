#!/usr/bin/env bash
set -Eeuo pipefail
#########################################
# NexusCore Repository Setup v1
#########################################
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"
log() {
    printf "${GREEN}✔${NC} %s\n" "$1"
}
warn() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}
fail() {
    printf "${RED}✖ %s${NC}\n" "$1"
    exit 1
}
echo
echo "======================================="
echo " NexusCore Repository Setup"
echo "======================================="
echo
#########################################
# Environment
#########################################
for cmd in git cargo rustc; do
    command -v "$cmd" >/dev/null 2>&1 || fail "$cmd not installed"
done
log "Rust installed"
log "Cargo installed"
log "Git installed"
#########################################
# Directory Structure
#########################################
mkdir -p apps
mkdir -p crates
mkdir -p assets/{branding,icons,images,fonts,themes}
mkdir -p bootstrap
mkdir -p configs/{development,production,providers,models,specialists}
mkdir -p docs/{api,developer,user,examples,tutorials}
mkdir -p knowledge/{architecture,engineering,adr,research,roadmap,providers,specialists,internal}
mkdir -p scripts
mkdir -p tests/{unit,integration,performance,benchmark}
mkdir -p tools/{builder,generator,installer,diagnostics,migration}
mkdir -p archive/{zip,legacy}
log "Directory structure verified"
#########################################
# Archive Old Phase Folders
#########################################
archive_if_exists() {
    local target="$1"
    if [ -d "$target" ]; then
        mv "$target" archive/legacy/
        log "Archived $target"
    fi
}
archive_zip() {
    shopt -s nullglob
    for f in *.zip; do
        mv "$f" archive/zip/
    done
    shopt -u nullglob
}
archive_if_exists "NexusCore_Phase1_Bootstrap"
archive_if_exists "NexusCore_Phase2_Engineering_Foundation"
archive_if_exists "NexusCore_Phase2_1_NKS"
archive_if_exists "NexusCore_Phase3_SystemSpecifications"
archive_if_exists "NexusCore_Project_Control_Center"
archive_zip
#########################################
# Create Cargo Packages
#########################################
create_bin() {
    local name="$1"
    if [ -f "apps/$name/Cargo.toml" ]; then
        log "$name already exists"
        return
    fi
    cargo new "apps/$name" --bin --vcs none
    log "$name created"
}
create_lib() {
    local name="$1"
    if [ -f "crates/$name/Cargo.toml" ]; then
        log "$name already exists"
        return
    fi
    cargo new "crates/$name" --lib --vcs none
    log "$name created"
}
create_bin cli
create_bin desktop
create_lib common
create_lib config
create_lib logger
create_lib filesystem
create_lib workspace
create_lib coremind
create_lib router
create_lib providers
create_lib specialists
create_lib memory
create_lib export
create_lib ui
#########################################
# Generate Workspace Cargo.toml
#########################################
cat > Cargo.toml <<EOF
[workspace]
resolver = "2"
members = [
    "apps/cli",
    "apps/desktop",
    "crates/common",
    "crates/config",
    "crates/logger",
    "crates/filesystem",
    "crates/workspace",
    "crates/coremind",
    "crates/router",
    "crates/providers",
    "crates/specialists",
    "crates/memory",
    "crates/export",
    "crates/ui"
]
EOF
log "Workspace generated"
#########################################
# Verify
#########################################
cargo check
echo
echo "======================================="
echo " NexusCore Repository Ready"
echo "======================================="
echo