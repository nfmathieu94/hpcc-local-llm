# Notes

Steps to run `Qwen/Qwen3-Coder-Next-FP8` from this repository and connect a local coding TUI to it.

System requirements:
- At least 2 GPUs with about 90 GB combined VRAM
- At least 100 GB system RAM
- About 85 GB free disk for Hugging Face model weights

## Directory Structure

`scripts/` = helper scripts

`logs/` = runtime and Slurm logs

`sif/` = Singularity image location

`hf_home/` and `cache/` = optional runtime caches if the tools create them

## Before Getting Started

Install one or both client tools:  
`npm install -g opencode-ai`  
`npm install -g @qwen-code/qwen-code`  

From the repository root, make sure the vLLM container exists at:
`sif/vllm-openai.sif`

If needed, create it from the repository root:  
`cd sif`  
`singularity pull vllm-openai.sif docker://vllm/vllm-openai:latest`  
`cd ../running_local_LLM`  

## Starting The Server

From the repository root, start an interactive GPU job:  
`srun -p short_gpu --gres=gpu:2 --cpus-per-task=8 -n 1 --mem=100G --time=02:00:00 --pty bash -l`

Check that the two GPUs provide enough VRAM:  
`nvidia-smi`

Start the server from the repository root:  
`bash scripts/run_coder_vllm_server.sh`

## Connecting A Client

Take note of the GPU hostname (ex. gpu06, gppu07, etc.) from the server terminal, then in another HPCC terminal set:  
`export OPENAI_API_KEY="local" OPENAI_BASE_URL="http://<gpu-node-hostname>:8000/v1" OPENAI_MODEL="Qwen/Qwen3-Coder-Next-FP8"`  

### Qwen Code

Start Qwen Code:  
`qwen`

Inside Qwen Code, run `/auth` and confirm:
- API Key: `local`
- Base URL: `http://<gpu-node-hostname>:8000/v1`
- Model: `Qwen/Qwen3-Coder-Next-FP8`

### OpenCode

Modify global or project-specific `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "vllm": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "vLLM (HPCC)",
      "options": {
        "baseURL": "http://<gpu-node-hostname>:8000/v1",
        "apiKey": "local"
      },
      "models": {
        "Qwen/Qwen3-Coder-Next-FP8": {
          "name": "Qwen 3 Coder Next FP8 (local vLLM)",
          "limit": { "context": 32768, "output": 4096 }
        }
      }
    }
  },
  "model": "vllm/Qwen/Qwen3-Coder-Next-FP8"
}
```
