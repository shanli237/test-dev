#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env_cuda122.sh
source scripts/env_local.sh
mkdir -p build/logs
test_bin="${NCCL_TEST_BIN:-/workspace/FuseLink/nccl-tests/build-cuda122/all_reduce_perf}"
# Local AllReduce can use NVLink. This verifies initialization and correctness,
# not transport over RDMA. NET=FuseLink prevents silent network fallback.
export NCCL_NET=FuseLink
export NCCL_IB_HCA="${NCCL_IB_HCA:-=mlx5_bond_5,mlx5_bond_6}"
export FUSELINK_NIC2GPU="${FUSELINK_NIC2GPU:-0,1}"
timeout "${TEST_TIMEOUT:-600s}" "$test_bin" -b 8 -e 1M -f 2 -g 2 -w 1 -n 3 2>&1 | tee build/logs/all_reduce_cuda122.log
