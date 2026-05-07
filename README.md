# CenterPoint TIDE Environment

Containerized CenterPoint/OpenPCDet research environment for LiDAR-based 3D object detection on SDSU's TIDE Kubernetes cluster powered by NRP Nautilus.

This repository provides a reproducible GPU-accelerated development environment for autonomous driving and 3D perception research using OpenPCDet, CenterPoint, PyTorch, CUDA, and SpConv. The goal is to simplify deployment across TIDE Kubernetes pods and eliminate repeated manual environment configuration.

---

## Features

- CUDA 12.4 + cuDNN development environment
- PyTorch GPU acceleration
- OpenPCDet preconfigured
- CenterPoint-compatible environment
- SpConv installation and verification
- Kubernetes-compatible Docker workflow
- Reproducible deployment across SDSU TIDE pods
- NRP GitLab Registry integration
- Runtime helper scripts for OpenPCDet compilation
- Designed for collaborative LiDAR research workflows

---

## System Architecture

The repository separates environment definition from container image hosting.

```text
GitHub Repository
    ↓
Docker Build
    ↓
NRP GitLab Container Registry
    ↓
TIDE Kubernetes Pod
    ↓
Runtime OpenPCDet Compilation
    ↓
Training / Inference
```

### Infrastructure Roles

| Component | Purpose |
|---|---|
| GitHub Repository | Stores Dockerfile, scripts, and documentation |
| GitLab Registry | Hosts built Docker images globally |
| TIDE / Nautilus | Kubernetes-based GPU compute environment |
| OpenPCDet | 3D object detection framework |
| CenterPoint | LiDAR detection model architecture |

---

## Repository Structure

```text
centerpoint-tide/
├── Dockerfile
├── .dockerignore
├── README.md
├── scripts/
│   └── compile_openpcdet.sh
├── docs/
│   ├── tide_usage.md
│   └── troubleshooting.md
```

| Path | Description |
|---|---|
| Dockerfile | Reproducible CUDA + PyTorch environment definition |
| scripts/ | Runtime helper scripts |
| docs/ | Additional deployment and troubleshooting documentation |
| README.md | Main project documentation |

---

## Prerequisites

Before using this environment, ensure you have:

- Access to SDSU TIDE or NRP Nautilus
- Access to an NVIDIA GPU-enabled pod
- Docker installed locally (optional)
- Git installed
- Nautilus GitLab registry access

---

## Pulling the Prebuilt Image

The container image is hosted on the NRP Nautilus GitLab Container Registry.

NRP recommends using their internal GitLab registry for Kubernetes workloads due to improved performance and accessibility compared to Docker Hub.

### Login to Registry

```bash
docker login gitlab-registry.nrp-nautilus.io
```

### Pull Image

```bash
docker pull gitlab-registry.nrp-nautilus.io/centerpoint-research/centerpoint-tide:v1
```

---

## Running on TIDE / Nautilus

Configure your TIDE Kubernetes pod to use:

```text
gitlab-registry.nrp-nautilus.io/centerpoint-research/centerpoint-tide:v1
```

After pod startup:

```bash
docker run --gpus all -it \
    gitlab-registry.nrp-nautilus.io/centerpoint-research/centerpoint-tide:v1
```

---

## Runtime Setup

Some OpenPCDet components may require runtime compilation depending on mounted storage, editable installs, or CUDA extension behavior.

Run the helper script:

```bash
bash scripts/compile_openpcdet.sh
```

This script recompiles OpenPCDet CUDA extensions and validates environment dependencies.

---

## Verifying Installation

### Verify CUDA Access

```bash
nvidia-smi
```

### Verify PyTorch CUDA

```bash
python -c "import torch; print(torch.cuda.is_available())"
```

Expected output:

```text
True
```

### Verify SpConv

```bash
python -c "import spconv"
```

### Verify OpenPCDet

```bash
python -c "import pcdet"
```

---

## Using OpenPCDet

Navigate into the OpenPCDet directory:

```bash
cd OpenPCDet
```

Example training command:

```bash
python tools/train.py \
    --cfg_file tools/cfgs/kitti_models/centerpoint.yaml
```

Example evaluation command:

```bash
python tools/test.py \
    --cfg_file tools/cfgs/kitti_models/centerpoint.yaml \
    --ckpt <checkpoint_file>
```

---

## Dataset Setup

Datasets should be mounted or stored in persistent storage accessible by the Kubernetes pod.

Example structure:

```text
/data/
├── kitti/
├── nuscenes/
└── waymo/
```

Update dataset paths inside OpenPCDet configuration files as needed.

---

## GPU Verification

To verify GPU visibility inside the container:

```bash
nvidia-smi
```

You should see:
- NVIDIA GPU information
- CUDA version
- GPU memory utilization

If GPUs are not visible:
- Ensure the pod was launched with GPU resources enabled
- Verify NVIDIA runtime availability
- See `docs/troubleshooting.md`

---

## Building Locally

### Clone Repository

```bash
git clone https://github.com/<your-org>/centerpoint-tide.git
cd centerpoint-tide
```

### Build Docker Image

```bash
docker build -t centerpoint-tide:v1 .
```

### Run Container

```bash
docker run --gpus all -it centerpoint-tide:v1
```

---

## Docker Image Details

| Component | Version |
|---|---|
| Base Image | nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04 |
| Ubuntu | 22.04 |
| Python | 3.10.12 |
| CUDA Toolkit | 12.4 |
| PyTorch | 2.5.1+cu124 |
| OpenPCDet | Installed |
| SpConv | Installed |

---

## Troubleshooting

Common issues include:

- CUDA driver mismatch
- SpConv import failures
- OpenPCDet editable build hangs
- GPU allocation issues in Kubernetes
- Docker layer push failures
- Registry authentication problems

See:

```text
docs/troubleshooting.md
```

for detailed solutions.

---

## Future Work

Planned improvements include:

- Automated runtime initialization
- Distributed multi-GPU training
- Dataset mounting automation
- CenterPoint benchmarking workflows
- Evaluation and visualization tooling
- Kubernetes job automation
- Experiment tracking integration

---

## Credits / References

### Frameworks

- OpenPCDet
- CenterPoint
- PyTorch
- SpConv

### Infrastructure

- SDSU Autonomy Research Center (ARCS)
- SDSU TIDE Cluster
- NRP Nautilus

### References

- OpenPCDet: https://github.com/open-mmlab/OpenPCDet
- CenterPoint Paper: https://arxiv.org/abs/2006.11275
- NRP Nautilus Documentation: https://nrp.ai/documentation/

---

## License

This repository is intended for research and educational use.
