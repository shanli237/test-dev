#!/usr/bin/env bash
set -euo pipefail
check_node() {
  local label=$1; shift
  echo "== $label =="
  "$@" nvidia-smi --query-gpu=index,uuid,memory.used,utilization.gpu --format=csv,noheader,nounits
  "$@" bash -lc 'python3 /workspace/FuseLink/FuseLink/scripts/select_idle_gpus.py'
}
check_node local
check_node node110 ssh root@11.163.39.110
