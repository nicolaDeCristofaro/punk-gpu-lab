#!/usr/bin/env bash
set -euo pipefail

# Minimal dependencies to run gradio.py using uv + venv
ENV_DIR="${ENV_DIR:-$HOME/.venvs/gradio-venv}"
PY_VER="${PY_VER:-3.11}"
# Default to CUDA 12.1 wheels (recommended for NVIDIA L4)
TORCH_INDEX_URL="${TORCH_INDEX_URL:-https://download.pytorch.org/whl/cu121}"

# --- Ensure uv ---------------------------------------------------------------
if ! command -v uv >/dev/null 2>&1; then
  echo "[+] Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

# --- Ensure requested Python -------------------------------------------------
if ! command -v "python${PY_VER}" >/dev/null 2>&1; then
  echo "[+] Installing Python ${PY_VER} via uv..."
  uv python install "${PY_VER}"
fi

# --- Create a virtualenv with uv --------------------------------------
echo "[+] Creating fresh venv at ${ENV_DIR} (Python ${PY_VER})"
rm -rf "${ENV_DIR}" || true
uv venv --python "${PY_VER}" "${ENV_DIR}"
PYBIN="${ENV_DIR}/bin/python"

# --- Minimal requirements ----------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQ_FILE="${SCRIPT_DIR}/requirements.txt"
cat > "${REQ_FILE}" <<'EOF'
gradio
transformers
accelerate
bitsandbytes
EOF

# --- Install dependencies ----------------------------------------------------
echo "[+] Installing PyTorch from ${TORCH_INDEX_URL}"
uv pip install -p "${PYBIN}" --upgrade --index-url "${TORCH_INDEX_URL}" torch

echo "[+] Installing packages from requirements.txt"
uv pip install -p "${PYBIN}" --upgrade -r "${REQ_FILE}"

# --- Smoke test --------------------------------------------------------------
"${PYBIN}" - <<'PY'
import torch, sys
print("Torch:", torch.__version__, "| CUDA available:", torch.cuda.is_available(), "| CUDA build:", torch.version.cuda)
sys.exit(0)
PY

echo
echo "[✓] Setup complete."
echo "Run the demo with:"
echo "  ${PYBIN} /mnt/persistent-data/punk-gpu-lab/python-samples/small-llm.py"