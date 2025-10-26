# Building Lyra Apptainer Container on Your Laptop

This document explains how to build the Lyra training container on your local machine and transfer it to the Alliance cluster.

## Table of Contents
1. [Why Build Locally](#why-build-locally)
2. [Laptop Requirements](#laptop-requirements)
3. [Container Definition File](#container-definition-file)
4. [Installation Steps](#installation-steps)
5. [Building the Container](#building-the-container)
6. [Transferring to Cluster](#transferring-to-cluster)
7. [Using the Container on Cluster](#using-the-container-on-cluster)
8. [Troubleshooting](#troubleshooting)

---

## Why Build Locally

### Problems with building on the cluster:
- **No root access**: Container builds require privileged operations you can't perform on the cluster
- **Filesystem incompatibility**: The cluster's Lustre/GPFS filesystems lack features needed for container builds
- **File quota consumption**: Building creates thousands of temporary files that consume your quota
- **Build failures**: Many containers simply cannot be built without root privileges

### Benefits of building locally:
- **Full control**: You have sudo/root access on your laptop
- **No restrictions**: Standard Linux filesystems support all build operations
- **Quota friendly**: Only the final .sif file (1 file, ~5-10GB) counts against cluster quota
- **Reusable**: Can rebuild/modify anytime without cluster resources
- **Officially recommended**: Alliance Canada recommends this approach

---

## Laptop Requirements

### Operating System
You need a **Linux x86_64 system**. You have several options:

#### Option 1: Native Linux (Best)
- Ubuntu 20.04, 22.04, or 24.04
- Fedora, Debian, or other major distribution
- Architecture: **x86_64** (AMD64/Intel 64-bit)

#### Option 2: WSL2 on Windows (Good)
- Windows 10/11 with WSL2 enabled
- Ubuntu 22.04 installed in WSL2
- **Note**: WSL1 will NOT work, must be WSL2

#### Option 3: Linux Virtual Machine (Good)
- VirtualBox, VMware, or Parallels
- Ubuntu 22.04 VM with at least 50GB disk space
- **Note**: VM must be x86_64 architecture

#### Option 4: macOS (Conditional)
- **Intel Mac**: Can use Docker Desktop or VM (x86_64)
- **Apple Silicon (M1/M2/M3)**: Can use Docker with cross-platform build
- Native Apptainer not available on macOS

### Hardware Requirements
- **Architecture**: x86_64 (Intel/AMD 64-bit) - must match cluster
- **RAM**: 8GB minimum, 16GB+ recommended
- **Disk Space**:
  - 20GB for container build process
  - 5-10GB for final .sif file
  - 50GB+ total free space recommended
- **Internet**: Stable connection for downloading base images and packages
- **CPU**: Multi-core recommended (build will be faster)

### Software Requirements
- Apptainer 1.1.0+ (or Singularity 3.8+)
- sudo/root access
- Internet connection
- Git (to get the lyra.def file)

**Note**: You do NOT need NVIDIA GPU on your laptop to build the container. The GPU is only needed to run it on the cluster.

---

## Container Definition File

The following is the complete `lyra.def` file that defines the container. Save this to a file named `lyra.def` on your laptop:

```
Bootstrap: docker
From: nvidia/cuda:12.4.1-devel-ubuntu22.04

%post
    # Set environment variables
    export DEBIAN_FRONTEND=noninteractive
    export CUDA_HOME=/usr/local/cuda

    # Update and install system dependencies
    apt-get update && apt-get install -y \
        software-properties-common \
        wget \
        git \
        build-essential \
        cmake \
        ninja-build \
        vim \
        && rm -rf /var/lib/apt/lists/*

    # Install GCC 12
    add-apt-repository ppa:ubuntu-toolchain-r/test -y
    apt-get update && apt-get install -y \
        gcc-12 \
        g++-12 \
        && rm -rf /var/lib/apt/lists/*

    # Set GCC 12 as default
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100

    # Install Python 3.10
    add-apt-repository ppa:deadsnakes/ppa -y
    apt-get update && apt-get install -y \
        python3.10 \
        python3.10-dev \
        python3.10-venv \
        python3-pip \
        && rm -rf /var/lib/apt/lists/*

    # Set Python 3.10 as default
    update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

    # Upgrade pip
    python3.10 -m pip install --upgrade pip setuptools wheel

    # Create a working directory
    mkdir -p /workspace
    cd /workspace

%environment
    export CUDA_HOME=/usr/local/cuda
    export PATH=/usr/local/cuda/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
    export PYTHONPATH=/workspace:$PYTHONPATH

%runscript
    echo "Lyra training container"
    echo "CUDA version: $(nvcc --version | grep release)"
    echo "Python version: $(python --version)"
    echo "GCC version: $(gcc --version | head -n1)"
    exec /bin/bash "$@"

%labels
    Author Lyra Setup
    Version v1.0
    Description Apptainer container for NVIDIA Lyra training
```

### What this definition file does:

**Bootstrap section:**
- `Bootstrap: docker` - Uses a Docker image as the base
- `From: nvidia/cuda:12.4.1-devel-ubuntu22.04` - NVIDIA's official CUDA 12.4.1 image with development tools on Ubuntu 22.04

**%post section** (runs during build with root privileges):
1. Sets environment variables to avoid interactive prompts
2. Installs system tools: git, cmake, ninja, build-essential
3. Installs GCC 12 from Ubuntu toolchain PPA and sets it as default compiler
4. Installs Python 3.10 from deadsnakes PPA and sets it as default
5. Upgrades pip, setuptools, and wheel
6. Creates `/workspace` directory for mounting your code

**%environment section** (sets environment variables every time container runs):
- `CUDA_HOME` - Points to CUDA installation
- `PATH` - Adds CUDA binaries to path
- `LD_LIBRARY_PATH` - Adds CUDA libraries for runtime linking
- `PYTHONPATH` - Adds workspace to Python import path

**%runscript section** (runs when you execute the container):
- Displays CUDA, Python, and GCC versions for verification
- Launches bash shell

**%labels section** (metadata):
- Author, version, and description information

---

## Installation Steps

### Step 1: Verify Your System Architecture

```bash
uname -m
```

**Expected output**: `x86_64`

If you see `aarch64`, `arm64`, or anything else, your laptop is NOT x86_64 and you'll need to use the Docker cross-platform build method (see Troubleshooting section).

### Step 2: Install Apptainer

#### On Ubuntu/Debian:

```bash
# Update package list
sudo apt-get update

# Install dependencies
sudo apt-get install -y \
    wget \
    build-essential \
    libseccomp-dev \
    pkg-config \
    uidmap \
    squashfs-tools \
    fakeroot \
    cryptsetup \
    tzdata \
    curl

# Download Apptainer (version 1.3.5 to match cluster)
cd /tmp
wget https://github.com/apptainer/apptainer/releases/download/v1.3.5/apptainer_1.3.5_amd64.deb

# Install the package
sudo dpkg -i apptainer_1.3.5_amd64.deb

# Verify installation
apptainer --version
```

**Expected output**: `apptainer version 1.3.5`

#### On Fedora/RHEL/CentOS:

```bash
# Install dependencies
sudo dnf install -y apptainer

# Verify installation
apptainer --version
```

#### On WSL2 (Ubuntu):
Follow the Ubuntu/Debian instructions above inside your WSL2 Ubuntu terminal.

### Step 3: Create the Container Definition File

Create a directory for your container build and save the definition file:

```bash
# On your laptop
mkdir -p ~/lyra-container
cd ~/lyra-container

# Create the lyra.def file
# Copy the entire content from the "Container Definition File" section above
# and save it as lyra.def
```

You can create it with a text editor or use this command:

```bash
cat > lyra.def << 'EOF'
Bootstrap: docker
From: nvidia/cuda:12.4.1-devel-ubuntu22.04

%post
    # Set environment variables
    export DEBIAN_FRONTEND=noninteractive
    export CUDA_HOME=/usr/local/cuda

    # Update and install system dependencies
    apt-get update && apt-get install -y \
        software-properties-common \
        wget \
        git \
        build-essential \
        cmake \
        ninja-build \
        vim \
        && rm -rf /var/lib/apt/lists/*

    # Install GCC 12
    add-apt-repository ppa:ubuntu-toolchain-r/test -y
    apt-get update && apt-get install -y \
        gcc-12 \
        g++-12 \
        && rm -rf /var/lib/apt/lists/*

    # Set GCC 12 as default
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100

    # Install Python 3.10
    add-apt-repository ppa:deadsnakes/ppa -y
    apt-get update && apt-get install -y \
        python3.10 \
        python3.10-dev \
        python3.10-venv \
        python3-pip \
        && rm -rf /var/lib/apt/lists/*

    # Set Python 3.10 as default
    update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

    # Upgrade pip
    python3.10 -m pip install --upgrade pip setuptools wheel

    # Create a working directory
    mkdir -p /workspace
    cd /workspace

%environment
    export CUDA_HOME=/usr/local/cuda
    export PATH=/usr/local/cuda/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
    export PYTHONPATH=/workspace:$PYTHONPATH

%runscript
    echo "Lyra training container"
    echo "CUDA version: $(nvcc --version | grep release)"
    echo "Python version: $(python --version)"
    echo "GCC version: $(gcc --version | head -n1)"
    exec /bin/bash "$@"

%labels
    Author Lyra Setup
    Version v1.0
    Description Apptainer container for NVIDIA Lyra training
EOF
```

---

## Building the Container

### Step 1: Set Up Build Environment

```bash
# Create directories for Apptainer cache/tmp (avoids filling up /tmp)
mkdir -p ~/apptainer-build/cache
mkdir -p ~/apptainer-build/tmp

# Set environment variables
export APPTAINER_CACHEDIR=~/apptainer-build/cache
export APPTAINER_TMPDIR=~/apptainer-build/tmp
```

**Why**: This ensures build artifacts go to your home directory instead of /tmp, which might have limited space.

### Step 2: Build the Container Image

```bash
# Navigate to directory containing lyra.def
cd ~/lyra-container

# Build the container (requires sudo)
sudo -E apptainer build lyra.sif lyra.def
```

**Flags explained**:
- `sudo`: Required for privileged operations during build
- `-E`: Preserves environment variables (APPTAINER_CACHEDIR, etc.)
- `build`: Apptainer command to build a container
- `lyra.sif`: Output filename (.sif = Singularity Image Format)
- `lyra.def`: Input definition file (the recipe)

**What happens during build**:
1. Downloads NVIDIA CUDA 12.4.1 base image (~3-5GB)
2. Installs system packages (GCC, Python, cmake, etc.)
3. Configures the environment
4. Creates compressed .sif file

**Expected time**: 10-30 minutes depending on internet speed and CPU

**Expected output**: You'll see:
```
INFO:    Starting build...
INFO:    Fetching container from docker://nvidia/cuda:12.4.1-devel-ubuntu22.04
...
[lots of installation output]
...
INFO:    Creating SIF file...
INFO:    Build complete: lyra.sif
```

### Step 3: Verify the Build

```bash
# Check the file was created
ls -lh lyra.sif

# Test the container (optional - doesn't require GPU)
apptainer exec lyra.sif python --version
apptainer exec lyra.sif gcc --version
apptainer exec lyra.sif nvcc --version
```

**Expected output**:
- File size: ~5-10GB
- Python version: 3.10.x
- GCC version: 12.x
- NVCC version: 12.4

**Why verify**: Ensures the container built successfully and has the right versions.

---

## Transferring to Cluster

### Step 1: Compress (Optional but Recommended)

```bash
# Optional: compress for faster transfer
gzip lyra.sif
```

This creates `lyra.sif.gz` which is ~30-50% smaller.

**Why**: Faster transfer over network, saves bandwidth.

### Step 2: Transfer to Cluster

```bash
# Transfer the file (replace with your actual credentials)
scp lyra.sif.gz username@cluster.computecanada.ca:/home/username/NVProject/lyra/

# Or if you didn't compress:
scp lyra.sif username@cluster.computecanada.ca:/home/username/NVProject/lyra/
```

**Alternative using rsync** (resumes on failure):
```bash
rsync -avz --progress lyra.sif.gz username@cluster:/home/username/NVProject/lyra/
```

**Expected time**: 10-60 minutes depending on internet speed and file size.

### Step 3: Decompress on Cluster (if compressed)

```bash
# SSH into cluster
ssh username@cluster.computecanada.ca

# Navigate to directory
cd /home/username/NVProject/lyra/

# Decompress
gunzip lyra.sif.gz

# Verify
ls -lh lyra.sif
```

---

## Using the Container on Cluster

### Step 1: Load Required Modules

```bash
# On the cluster
module load apptainer/1.3.5
```

### Step 2: Test the Container

```bash
# Test without GPU
apptainer exec lyra.sif python --version

# Test with GPU access (on a GPU node)
apptainer exec --nv lyra.sif nvidia-smi
```

**Flags explained**:
- `--nv`: Enables NVIDIA GPU support (binds GPU drivers into container)

### Step 3: Start Interactive Shell

```bash
# Start interactive session in container
apptainer shell --nv lyra.sif
```

You're now inside the container! The prompt will change.

### Step 4: Running with Bind Mounts

To access your Lyra code and data from inside the container:

```bash
# On cluster, outside container
apptainer shell --nv \
  --bind /home/username/NVProject/lyra:/workspace \
  --bind /path/to/lyra_dataset:/data \
  lyra.sif
```

**What --bind does**:
- Mounts cluster directories inside the container
- Format: `--bind /cluster/path:/container/path`
- Your files appear at `/container/path` inside the container

### Step 5: Installing Python Packages (Inside Container)

```bash
# Inside container, after bind mounting
cd /workspace
pip install -r requirements_gen3c.txt
pip install -r requirements_lyra.txt

# Install specialized libraries
pip install transformer-engine[pytorch]==1.12.0

# Clone and install apex
git clone https://github.com/NVIDIA/apex
CUDA_HOME=/usr/local/cuda pip install -v --disable-pip-version-check \
  --no-cache-dir --no-build-isolation \
  --config-settings "--build-option=--cpp_ext" \
  --config-settings "--build-option=--cuda_ext" ./apex

# Install other dependencies
pip install git+https://github.com/microsoft/MoGe.git
pip install --no-build-isolation "git+https://github.com/state-spaces/mamba@v2.2.4"
pip install git+https://github.com/Dao-AILab/causal-conv1d@v1.4.0
pip install git+https://github.com/nerfstudio-project/gsplat.git@73fad53c31ec4d6b088470715a63f432990493de
pip install git+https://github.com/rahul-goel/fused-ssim/@8bdb59feb7b9a41b1fab625907cb21f5417deaac
```

**Where packages are installed**:
- By default, pip installs to container's filesystem
- This is **lost** when you exit the container
- To persist: use `--bind $HOME/.local:/root/.local` or create a writable overlay

### Alternative: Writable Overlay (Recommended for Python packages)

```bash
# Create overlay directory (on cluster, outside container)
mkdir -p ~/lyra-overlay

# Run container with overlay
apptainer shell --nv \
  --overlay ~/lyra-overlay \
  --bind /home/username/NVProject/lyra:/workspace \
  lyra.sif

# Now pip installs persist in ~/lyra-overlay
```

---

## Troubleshooting

### Problem: "Architecture mismatch" or "exec format error"

**Cause**: You built on ARM (M1/M2 Mac) but cluster is x86_64

**Solution**: Use Docker with cross-platform build:

```bash
# On Mac with Apple Silicon
# First convert lyra.def to Dockerfile (manually or with helper script)
# Then build for x86_64:
docker buildx build --platform linux/amd64 -t lyra:latest .

# Save to tar
docker save lyra:latest -o lyra.tar

# Transfer and convert on cluster:
apptainer build lyra.sif docker-archive://lyra.tar
```

### Problem: "No space left on device" during build

**Cause**: /tmp is full

**Solution**: Set APPTAINER_TMPDIR as shown in Step 1 of building

### Problem: "permission denied" when running sudo apptainer build

**Cause**: Your user doesn't have sudo access

**Solutions**:
1. Use `apptainer build --fakeroot` (if fakeroot is configured)
2. Build in a VM where you have root
3. Ask Alliance staff to build for you (submit ticket)

### Problem: Container build hangs or is very slow

**Cause**: Slow internet or underpowered laptop

**Solutions**:
1. Use wired connection instead of WiFi
2. Build overnight
3. Use a cloud VM (AWS, GCP) with better bandwidth

### Problem: CUDA version mismatch warnings on cluster

**Cause**: Container has CUDA 12.4, cluster drivers might be different

**Solution**: Usually safe to ignore warnings. Container CUDA works with newer cluster drivers.

### Problem: Python packages fail to install in container

**Cause**: Version conflicts or missing system dependencies

**Solution**:
1. Check error message for missing libraries
2. May need to add dependencies to lyra.def and rebuild
3. Or install in overlay/bind mount as shown above

---

## Summary Checklist

### On Your Laptop:
- [ ] Verify architecture is x86_64 (`uname -m`)
- [ ] Install Apptainer 1.3.5
- [ ] Create lyra.def file (from section above)
- [ ] Set APPTAINER_CACHEDIR and APPTAINER_TMPDIR
- [ ] Run `sudo -E apptainer build lyra.sif lyra.def`
- [ ] Verify build: `ls -lh lyra.sif`
- [ ] Test: `apptainer exec lyra.sif python --version`
- [ ] Compress: `gzip lyra.sif` (optional)
- [ ] Transfer: `scp lyra.sif.gz user@cluster:/path/`

### On the Cluster:
- [ ] Decompress if needed: `gunzip lyra.sif.gz`
- [ ] Load module: `module load apptainer/1.3.5`
- [ ] Test: `apptainer exec lyra.sif python --version`
- [ ] Create overlay: `mkdir ~/lyra-overlay`
- [ ] Run with GPU: `apptainer shell --nv --overlay ~/lyra-overlay --bind /path/to/lyra:/workspace lyra.sif`
- [ ] Install Python packages inside container
- [ ] Download training data
- [ ] Configure data paths
- [ ] Ready to train!

---

## Additional Resources

- Alliance Apptainer docs: https://docs.alliancecan.ca/wiki/Apptainer
- Apptainer user guide: https://apptainer.org/docs/user/latest/
- NVIDIA CUDA containers: https://hub.docker.com/r/nvidia/cuda

## Questions?

If you encounter issues not covered here:
1. Check Alliance documentation
2. Submit support ticket to Alliance
3. Review Apptainer GitHub issues
4. Check Lyra repository issues

---

**Document Version**: 1.0
**Last Updated**: 2025-10-25
**Lyra Repository**: https://github.com/nv-tlabs/lyra
