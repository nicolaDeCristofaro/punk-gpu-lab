#!/usr/bin/env bash
set -euo pipefail

PREFIX="$HOME/miniconda3"
ENV="gradio-gpu"

# --- Miniconda ----------------------------------------------------------------
curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
     -o /tmp/miniconda.sh
bash /tmp/miniconda.sh -b -p "$PREFIX"
eval "$("$PREFIX/bin/conda" shell.bash hook)"
conda init bash

# --- Conda env ----------------------------------------------------------------
# Accept Anaconda default-channel ToS (needed once per machine)
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

conda create -y -n "$ENV" python=3.11
conda run -n "$ENV" python -m pip install --upgrade \
  --extra-index-url https://download.pytorch.org/whl/cu118 \
  torch==2.7.1+cu118

conda run -n "$ENV" python -m pip install --upgrade \
  transformers accelerate bitsandbytes peft trl gradio

# --- Smoke test ---------------------------------------------------------------
conda run -n "$ENV" --live-stream python - <<'PY'
import torch, textwrap, sys
ok = torch.cuda.is_available()
print("CUDA OK:", ok, "| Build for", torch.version.cuda, "| Device:",
      torch.cuda.get_device_name(0) if ok else "n/a")
sys.exit(0 if ok else 1)
PY