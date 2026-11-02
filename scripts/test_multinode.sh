#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v mpirun >/dev/null || { echo 'Install Open MPI on both nodes first.' >&2; exit 1; }
args=()
if [[ $(id -u) == 0 ]]; then args+=(--allow-run-as-root); fi
mkdir -p build/logs
mpirun "${args[@]}" --hostfile config/hosts.two_nodes -np 2 \
  --map-by ppr:1:node --bind-to none \
  bash /workspace/FuseLink/FuseLink/scripts/run_multinode_rank.sh \
  2>&1 | tee build/logs/multinode.log
