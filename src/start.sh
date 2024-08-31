#!/usr/bin/env bash

echo "Worker Initiated"

# Symlink files from Network Volume
echo "Symlinking files from Network Volume"
rm -rf /workspace && \
  ln -s /runpod-volume /workspace

# Activate the virtual environment and start ComfyUI
if [ -f "/workspace/venv/bin/activate" ]; then
    echo "Starting ComfyUI in Python Environment"
    source /workspace/venv/bin/activate

    # Use libtcmalloc for better memory management
    TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
    export LD_PRELOAD="${TCMALLOC}"
    export PYTHONUNBUFFERED=true

    # Serve the API and don't shutdown the container
    if [ "$SERVE_API_LOCALLY" == "true" ]; then
        echo "runpod-worker-comfy: Starting ComfyUI"
        python3 /workspace/ComfyUI/main.py --disable-auto-launch --disable-metadata --listen &

        echo "runpod-worker-comfy: Starting RunPod Handler"
        python3 -u /rp_handler.py --rp_serve_api --rp_api_host=0.0.0.0
    else
        echo "runpod-worker-comfy: Starting ComfyUI"
        python3 /workspace/ComfyUI/main.py --disable-auto-launch --disable-metadata &

        echo "runpod-worker-comfy: Starting RunPod Handler"
        python3 -u /rp_handler.py
    fi

    deactivate
else
    echo "ERROR: The Python Virtual Environment (/workspace/venv/bin/activate) could not be activated"
    echo "1. Ensure that you have followed the installation instructions."
    echo "2. Ensure that you are using the correct environment and setup."
fi
