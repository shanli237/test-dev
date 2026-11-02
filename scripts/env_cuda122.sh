# Usage: source scripts/env_cuda122.sh
export CUDA_HOME=/usr/local/cuda-12.2
export PATH="$CUDA_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"
export CC=/usr/bin/gcc-12
export CXX=/usr/bin/g++-12
export NVCC_CCBIN=/usr/bin/g++-12
