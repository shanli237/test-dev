#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env_multinode.sh
exec /workspace/FuseLink/nccl-tests/build-cuda122-mpi/all_reduce_perf \
  -b 8 -e 64K -f 2 -g 2 -w 1 -n 3
