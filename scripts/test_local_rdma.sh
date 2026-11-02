#!/usr/bin/env bash
# Local two-GPU RDMA correctness check, configured for mlx5_bond_5/6.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env_cuda122.sh
source scripts/env_local.sh
export NCCL_NET=FuseLink
export NCCL_IB_HCA="${NCCL_IB_HCA:-=mlx5_bond_5,mlx5_bond_6}"
export FUSELINK_NIC2GPU="${FUSELINK_NIC2GPU:-0,1}"
export FUSELINK_CHANNEL2NIC="${FUSELINK_CHANNEL2NIC:-0,1,0,1}"
export NCCL_FUSELINK_NCHANNELS=4 NCCL_MIN_NCHANNELS=4 NCCL_MAX_NCHANNELS=4
export NCCL_P2P_DISABLE=1 NCCL_SHM_DISABLE=1
# DMA-BUF registration returns EINVAL on the tested machine; legacy GDR works.
export NCCL_DMABUF_ENABLE=0 NCCL_NET_GDR_LEVEL=SYS
export NCCL_CUMEM_ENABLE=1 NCCL_NET_SHARED_BUFFERS=0
export NCCL_PROTO=Simple NCCL_ALGO=Ring
mkdir -p build/logs
timeout -k 5s "${TEST_TIMEOUT:-120s}" \
  "${NCCL_TEST_BIN:-/workspace/FuseLink/nccl-tests/build-cuda122/all_reduce_perf}" \
  -b 8 -e 64K -f 2 -g 2 -w 1 -n 2 2>&1 | tee build/logs/local_rdma.log
