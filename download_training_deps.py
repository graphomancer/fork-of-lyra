#!/usr/bin/env python3
"""
Download all pretrained models needed for Lyra training on compute nodes.
Run this on a login node before submitting jobs.
"""

import os
import sys

# Set cache directories
TORCH_HOME = "./pretrained_models/torch_hub"
os.environ['TORCH_HOME'] = TORCH_HOME

print("=" * 60)
print("Downloading pretrained models for Lyra training")
print("=" * 60)

# Create directories
os.makedirs(TORCH_HOME, exist_ok=True)
print(f"Using TORCH_HOME: {TORCH_HOME}")

# Download VGG16 weights for LPIPS loss
print("\n[1/1] Downloading VGG16 weights for LPIPS loss...")
try:
    import torch
    import torchvision
    from torchvision.models import vgg16, VGG16_Weights

    print("  Loading VGG16 with IMAGENET1K_V1 weights...")
    model = vgg16(weights=VGG16_Weights.IMAGENET1K_V1)
    print("  ✓ VGG16 weights downloaded successfully!")

    # Verify
    cache_dir = os.path.join(TORCH_HOME, "hub", "checkpoints")
    if os.path.exists(cache_dir):
        files = os.listdir(cache_dir)
        print(f"  Cache contains: {files}")
except Exception as e:
    print(f"  ✗ Error downloading VGG16: {e}")
    sys.exit(1)

print("\n" + "=" * 60)
print("All downloads complete!")
print("=" * 60)
print("\nNext steps:")
print("1. Download Cosmos tokenizer (requires HF access approval)")
print("2. Submit your training job with: sbatch run_training.slurm")
print("\nThe SLURM script has been configured to use these pretrained models.")
