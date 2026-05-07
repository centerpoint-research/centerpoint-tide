FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    CUDA_HOME=/usr/local/cuda \
    FORCE_CUDA=1 \
    TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0" \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-lc"]

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    build-essential \
    git \
    wget \
    curl \
    ca-certificates \
    cmake \
    ninja-build \
    pkg-config \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libboost-all-dev \
    ffmpeg && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-dev \
    python3.10-venv \
    python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Make Python 3.10 the default python
RUN ln -sf /usr/bin/python3.10 /usr/local/bin/python && \
    ln -sf /usr/bin/python3.10 /usr/local/bin/python3 && \
    python -m pip install --upgrade pip setuptools wheel

WORKDIR /workspace

# PyTorch stack pinned to the versions observed in your pod
RUN pip install --no-cache-dir \
    torch==2.5.1+cu124 \
    torchvision==0.20.1+cu124 \
    torchaudio==2.5.1+cu124 \
    --index-url https://download.pytorch.org/whl/cu124

# Build helpers for spconv
RUN pip install --no-cache-dir \
    pccm==0.4.16 \
    cumm-cu124==0.7.11 \
    pybind11 \
    fire \
    numpy

# Build and install spconv from source so the image does not depend on your pod state
WORKDIR /workspace
RUN git clone --branch v2.3.6 --depth 1 https://github.com/traveller59/spconv.git && \
    cd spconv && \
    pip install --no-cache-dir .

# OpenPCDet dependencies first, then pin the exact repo commit you reported
WORKDIR /workspace
RUN git clone https://github.com/open-mmlab/OpenPCDet.git

# Default runtime settings
ENV SPCONV_DISABLE_JIT=1 \
    PYTHONPATH=/workspace/OpenPCDet \
    PATH=/usr/local/cuda/bin:$PATH \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

WORKDIR /workspace/OpenPCDet

CMD ["bash"]
