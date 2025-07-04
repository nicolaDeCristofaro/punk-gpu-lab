#!/bin/bash
nvidia-smi -L || { echo "NVIDIA driver missing or not working"; exit 1; }yes