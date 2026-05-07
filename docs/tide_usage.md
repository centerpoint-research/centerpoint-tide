# TIDE / Nautilus Usage Guide

This document explains how the `centerpoint-tide` container image is intended to be used on SDSU TIDE / NRP Nautilus.

## Overview

This project uses a containerized workflow:

```text
GitHub Repository
    ↓
Dockerfile + setup scripts
    ↓
Built Docker Image
    ↓
NRP GitLab Container Registry
    ↓
TIDE / Nautilus Kubernetes Pod
    ↓
OpenPCDet / CenterPoint Runtime
```

The GitHub repository stores the reproducible build recipe and documentation.  
The NRP GitLab Container Registry stores the actual built image.

## Container Image

Current image:

```text
gitlab-registry.nrp-nautilus.io/centerpoint-research/centerpoint-tide:v1
```

## Important: Docker Is Not Run Inside JupyterHub Pods

TIDE JupyterHub pods usually do **not** include Docker.

This is expected.

Users should not expect to run:

```bash
docker pull ...
docker run ...
```

from inside a launched JupyterLab terminal.

Instead, Kubernetes pulls the image before the pod starts.

## How the Image Is Used

There are two expected ways this image may be used.

### Option 1: JupyterHub Image Selection

If TIDE administrators add the image to the available JupyterHub image options, users can select it when launching a notebook server.

In this case, the pod starts directly inside the CenterPoint/OpenPCDet environment.

### Option 2: Kubernetes Namespace Workflow

If the research group has Kubernetes namespace access, the image can be referenced in a Kubernetes pod, job, or deployment manifest:

```yaml
containers:
  - name: centerpoint
    image: gitlab-registry.nrp-nautilus.io/centerpoint-research/centerpoint-tide:v1
```

This requires namespace-level Kubernetes access and appropriate registry permissions.

## Namespace Context

The project operates under a Kubernetes namespace on Nautilus/TIDE.

A namespace provides isolation for project resources such as:

- pods
- jobs
- storage volumes
- secrets
- resource quotas

However, being a member of a namespace does not automatically mean every user can create or edit Kubernetes resources from inside JupyterHub.

Access depends on Kubernetes RBAC permissions.

## Checking for Kubernetes CLI Access

Inside a Jupyter terminal, check whether `kubectl` exists:

```bash
which kubectl
```

If it is unavailable, Kubernetes resources cannot be managed directly from that pod.

If it exists, check permissions:

```bash
kubectl auth can-i get pods
kubectl auth can-i create pods
kubectl auth can-i create jobs
```

If these return `no`, request access from the project or TIDE administrator.

## Registry Access

The image is stored in the NRP GitLab Container Registry.

If the registry project is private, Kubernetes may need an image pull secret to access it.

That setup is typically handled by a namespace or TIDE administrator.

## Runtime Setup

After the pod starts from the image, OpenPCDet may require runtime compilation or validation.

Run:

```bash
bash scripts/compile_openpcdet.sh
```

If OpenPCDet is stored in a non-default location:

```bash
OPENPCDET_DIR=/path/to/OpenPCDet bash scripts/compile_openpcdet.sh
```

## GPU Verification

After the pod starts, verify GPU visibility:

```bash
nvidia-smi
```

Verify PyTorch CUDA access:

```bash
python -c "import torch; print(torch.cuda.is_available())"
```

Expected output:

```text
True
```

## Storage Notes

Large datasets and checkpoints should not be stored in the GitHub repository.

Recommended storage targets:

- persistent project volumes
- namespace PVCs
- approved shared storage locations
- mounted dataset directories

Avoid storing large datasets, checkpoints, or experiment outputs inside the repository.

## Recommended User Workflow

1. Launch a TIDE/Nautilus pod using the custom image.
2. Verify GPU access with `nvidia-smi`.
3. Run the OpenPCDet compile script.
4. Mount or prepare datasets.
5. Run CenterPoint inference, evaluation, or training.

## Open Questions / Admin Setup

The following may require TIDE or namespace administrator support:

- adding the image to the JupyterHub image dropdown
- granting namespace-level Kubernetes access
- configuring image pull secrets
- provisioning persistent storage
- launching long-running jobs
- enabling multi-GPU workloads

## Summary

This repository does not require Docker inside the JupyterHub pod.

The correct model is:

```text
JupyterHub launches a Kubernetes pod
Kubernetes pulls the GitLab image
The user works inside the already-built CenterPoint environment
```