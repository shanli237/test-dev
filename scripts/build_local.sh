#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda-12.2}"
export CXX="${CXX:-/usr/bin/g++-12}"
# PTX lets the local driver compile GPU kernels for this machine.
make -C nccl -j"${JOBS:-8}" src.build CUDA_HOME="$CUDA_HOME" CXX="$CXX" \
  NVCC_GENCODE="${NVCC_GENCODE:--gencode=arch=compute_89,code=compute_89}"
make -j"${JOBS:-8}" fl CUDA_HOME="$CUDA_HOME" CXX="$CXX" NCCL_BUILD_DIR="$PWD/nccl/build"
export LD_LIBRARY_PATH="$PWD/build/lib:$PWD/nccl/build/lib:$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"
python3 scripts/verify_load.py
