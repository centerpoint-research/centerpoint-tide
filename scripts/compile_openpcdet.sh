#!/usr/bin/env bash

set -e

echo "=========================================="
echo " CenterPoint / OpenPCDet Runtime Compiler "
echo "=========================================="

# Default OpenPCDet location inside the container.
# Override this by running:
# OPENPCDET_DIR=/path/to/OpenPCDet bash scripts/compile_openpcdet.sh
OPENPCDET_DIR="${OPENPCDET_DIR:-/workspace/OpenPCDet}"

echo "[1/6] Checking OpenPCDet directory..."

if [ ! -d "$OPENPCDET_DIR" ]; then
    echo "ERROR: OpenPCDet directory not found at: $OPENPCDET_DIR"
    echo "Set OPENPCDET_DIR to the correct path and rerun this script."
    exit 1
fi

cd "$OPENPCDET_DIR"

echo "[2/6] Checking GPU visibility..."

if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi
else
    echo "WARNING: nvidia-smi not found. GPU may not be visible inside this container."
fi

echo "[3/6] Checking PyTorch CUDA..."

python - <<'PY'
import torch
print("PyTorch version:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())
print("CUDA version:", torch.version.cuda)
if not torch.cuda.is_available():
    raise RuntimeError("PyTorch cannot see CUDA. Check GPU allocation and NVIDIA runtime.")
PY

echo "[4/6] Checking SpConv..."

python - <<'PY'
try:
    import spconv
    print("SpConv import: OK")
except Exception as e:
    print("SpConv import: FAILED")
    raise e
PY

echo "[5/6] Installing OpenPCDet in editable mode..."

python setup.py develop

echo "[6/6] Verifying PCDet import..."

python - <<'PY'
import pcdet
print("PCDet import: OK")
PY

echo "=========================================="
echo " OpenPCDet runtime setup completed."
echo "=========================================="