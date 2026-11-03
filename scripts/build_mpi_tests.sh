#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env_cuda122.sh
make -C "${NCCL_TESTS_DIR:-/workspace/FuseLink/nccl-tests}" -j"${JOBS:-4}" \
  BUILDDIR=build-cuda122-mpi MPI=1 MPI_HOME=/usr \
  MPI_INCLUDE=/usr/lib/x86_64-linux-gnu/openmpi/include \
  CUDA_HOME="$CUDA_HOME" NCCL_HOME="$PWD/nccl/build" CXX="$CXX" \
  NVCC_GENCODE='-gencode=arch=compute_89,code=[sm_89,compute_89]'
