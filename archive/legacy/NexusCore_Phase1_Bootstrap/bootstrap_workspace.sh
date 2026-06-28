#!/usr/bin/env bash
set -e

echo "== NexusCore Bootstrap =="

mkdir -p crates/{common,config,logger,filesystem,workspace}
mkdir -p apps/desktop
mkdir -p assets scripts tests knowledge

for c in common config logger filesystem workspace
do
    if [ ! -d "crates/$crate" ]; then
    cargo new --lib "crates/$crate"
else
    cargo init --lib "crates/$crate"
fi
done

echo "Workspace initialized."
