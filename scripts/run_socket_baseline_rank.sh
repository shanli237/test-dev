#!/usr/bin/env bash
set -euo pipefail
cd /workspace/FuseLink/FuseLink
source scripts/env_cuda122.sh
source scripts/env_local.sh
CUDA_VISIBLE_DEVICES="$(python3 scripts/select_idle_gpus.py)"
export CUDA_VISIBLE_DEVICES
printf "Node %s GPU selection: %s\n" "$(hostname)" "$CUDA_VISIBLE_DEVICES"
export NCCL_NET_PLUGIN=none NCCL_NET=Socket NCCL_SOCKET_IFNAME='=eth0' NCCL_IB_DISABLE=1
unset NCCL_P2P_DISABLE NCCL_SHM_DISABLE
export NCCL_PROTO=Simple NCCL_ALGO=Ring
exec /workspace/FuseLink/nccl-tests/build-cuda122-mpi/all_reduce_perf -b 8 -e 64K -f 2 -g 2 -w 1 -n 3
