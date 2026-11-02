#!/usr/bin/env python3
"""Load freshly built libraries with immediate symbol resolution; no GPU workload."""
import ctypes
import os
from pathlib import Path

root = Path(__file__).resolve().parents[1]
mode = os.RTLD_NOW | os.RTLD_GLOBAL
nccl = ctypes.CDLL(str(root / 'nccl/build/lib/libnccl.so'), mode=mode)
version = ctypes.c_int()
nccl.ncclGetVersion.argtypes = [ctypes.POINTER(ctypes.c_int)]
nccl.ncclGetVersion.restype = ctypes.c_int
assert nccl.ncclGetVersion(ctypes.byref(version)) == 0
plugin = ctypes.CDLL(str(root / 'build/lib/libnccl-net-fuselink.so'), mode=mode)
class PluginHeader(ctypes.Structure):
    _fields_ = [('name', ctypes.c_char_p)]
for symbol in ('ncclNetPlugin_v7', 'ncclNetPlugin_v6'):
    header = PluginHeader.in_dll(plugin, symbol)
    print(f'{symbol}: {header.name.decode()}')
print(f'PASS: NCCL {version.value}, FuseLink loaded with RTLD_NOW')
