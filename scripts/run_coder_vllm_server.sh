#!/usr/bin/bash -l

set -euo pipefail

MODEL="${1:-Qwen/Qwen3-Coder-Next-FP8}"
PORT="${PORT:-8000}"
HOST="${HOST:-0.0.0.0}"

BASE_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
cd "$BASE_DIR"

SIF="sif/vllm-openai.sif"

# Calculate Tensor Parallel size automatically based on Slurm allocation
# If SLURM_GPUS_ON_NODE is set, use it; otherwise default to 1.
TP_SIZE="${SLURM_GPUS_ON_NODE:-2}"

export HF_HOME="hf_home"
export TRANSFORMERS_CACHE="$HF_HOME"
export HF_HUB_CACHE="$HF_HOME"
export XDG_CACHE_HOME="cache"

mkdir -p logs

if [[ ! -f "$SIF" ]]; then
  echo "[ERROR] Missing Singularity image: $SIF" >&2
  echo "[ERROR] Run this script from the project root or submit from there with Slurm." >&2
  exit 1
fi

echo "[INFO] Node: $(hostname)"
echo "[INFO] Model: $MODEL"
echo "[INFO] Serving on: http://$HOST:$PORT/v1"
echo "[INFO] Base dir: $BASE_DIR"
echo "[INFO] HF_HOME: $HF_HOME"
echo "[INFO] SIF: $SIF"

module load singularity-ce

singularity exec --cleanenv --nv \
  -B "$BASE_DIR":"$BASE_DIR" \
  "$SIF" \
  python3 -m vllm.entrypoints.openai.api_server \
    --model "$MODEL" \
    --tensor-parallel-size "$TP_SIZE" \
    --host "$HOST" \
    --port "$PORT" \
    --dtype auto \
    --enable-auto-tool-choice \
    --tool-call-parser qwen3_coder 
