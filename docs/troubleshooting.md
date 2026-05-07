# Troubleshooting Guide

This document collects common issues encountered while setting up and running the CenterPoint/OpenPCDet environment on SDSU TIDE / NRP Nautilus.

---

## Docker Is Not Available Inside JupyterHub

### Symptom

```bash
docker: command not found
```

### Explanation

This is expected. TIDE JupyterHub pods generally do not run Docker inside the notebook server.

Docker is used before the pod starts. Kubernetes pulls the container image directly.

### Fix

Do not run:

```bash
docker pull
docker run
```

inside JupyterHub.

Instead, launch the pod using the image:

```text
gitlab-registry.nrp-nautilus.io/centerpoint-research/centerpoint-tide:v1
```

---

## kubectl Is Not Available Inside JupyterHub

### Symptom

```bash
kubectl: command not found
```

### Explanation

Your notebook pod may not include the Kubernetes CLI, or your account may not have namespace-level RBAC permissions.

### Check

```bash
which kubectl
```

If installed:

```bash
kubectl auth can-i get pods
kubectl auth can-i create pods
kubectl auth can-i create jobs
```

### Fix

Request namespace access or ask a TIDE/namespace administrator to launch the workload.

---

## CUDA Runtime vs CUDA Toolkit

### Symptom

PyTorch sees CUDA:

```bash
python -c "import torch; print(torch.cuda.is_available())"
```

returns:

```text
True
```

but OpenPCDet fails to build with:

```text
CUDA_HOME environment variable is not set
```

or:

```text
fatal error: cuda.h: No such file or directory
```

### Explanation

PyTorch can run with the CUDA runtime, but OpenPCDet requires the CUDA Toolkit to compile custom CUDA extensions.

The CUDA Toolkit provides:

- `nvcc`
- `cuda.h`
- CUDA headers
- CUDA development libraries

### Fix

Use a container image that includes the CUDA Toolkit, or install the toolkit into a permitted user-space location.

Then set:

```bash
export CUDA_HOME=/path/to/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
```

Verify:

```bash
nvcc --version
```

---

## CUDA_HOME Is Not Set

### Symptom

```text
OSError: CUDA_HOME environment variable is not set.
```

### Fix

Find CUDA:

```bash
which nvcc
```

Then set:

```bash
export CUDA_HOME=/path/to/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
```

Example:

```bash
export CUDA_HOME=$HOME/cuda-12.4
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
```

Persist it:

```bash
echo 'export CUDA_HOME=$HOME/cuda-12.4' >> ~/.bashrc
echo 'export PATH=$CUDA_HOME/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
```

---

## SpConv Import Triggers JIT Compilation

### Symptom

Importing SpConv triggers a large build and fails with:

```text
fatal error: cuda.h: No such file or directory
```

### Explanation

SpConv may attempt JIT compilation of CUDA kernels at import time. This requires the CUDA Toolkit.

### Temporary Fix

Disable JIT:

```bash
export SPCONV_DISABLE_JIT=1
```

Then test:

```bash
python -c 'import spconv; print("spconv loaded")'
```

Persist it:

```bash
echo 'export SPCONV_DISABLE_JIT=1' >> ~/.bashrc
```

### Note

Disabling JIT can allow imports to succeed, but full OpenPCDet/CenterPoint CUDA execution still requires compiled CUDA extensions.

---

## OpenPCDet `setup.py develop` Fails Because Torch Is Missing

### Symptom

```text
ModuleNotFoundError: No module named 'torch'
```

### Explanation

OpenPCDet imports PyTorch during its build process. If PyTorch is not installed in the active environment, the build fails.

### Fix

Activate the correct environment and install PyTorch:

```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
```

Verify:

```bash
python -c "import torch; print(torch.__version__)"
python -c "import torch; print(torch.cuda.is_available())"
```

Then rerun:

```bash
python setup.py develop
```

---

## Conda Environment Disappears After Restart

### Symptom

A previously created environment no longer appears:

```bash
conda env list
```

### Explanation

If the environment was created with:

```bash
conda create -n centerpoint python=3.10
```

it may have been stored under the container filesystem, such as:

```text
/opt/conda/envs/
```

This may not persist across pod restarts.

### Fix

Create environments inside persistent home storage:

```bash
mkdir -p ~/envs
conda create -p ~/envs/centerpoint python=3.10 -y
conda activate ~/envs/centerpoint
```

---

## Conda Activate Does Not Work

### Symptom

```text
CommandNotFoundError: Your shell has not been properly configured to use 'conda activate'
```

### Fix

Load Conda manually:

```bash
source /opt/conda/etc/profile.d/conda.sh
conda activate ~/envs/centerpoint
```

Persist the Conda hook:

```bash
echo 'source /opt/conda/etc/profile.d/conda.sh' >> ~/.bashrc
source ~/.bashrc
```

---

## Disk Quota / Storage Issues

### Symptom

```text
No space left on device
```

or package installs fail due to storage limits.

### Explanation

JupyterHub home directories may have limited persistent storage. Datasets, checkpoints, and environments can quickly exceed quotas.

### Fix

Use approved persistent project storage or PVCs for:

- datasets
- checkpoints
- large logs
- experiment outputs
- model weights

Avoid committing or storing these inside the GitHub repository.

---

## CephFS and Conda/Pip Restrictions

### Symptom

Admin documentation states that Conda/Pip installs are not allowed on shared CephFS.

### Explanation

Conda and pip create many small files and can overload shared filesystem metadata services.

### Fix

Use CephFS only for large files such as:

- datasets
- checkpoints
- pretrained weights
- archives

Do not install Python environments there unless explicitly permitted.

---

## GPU Pod Scheduling Fails

### Symptom

Pod startup shows messages like:

```text
0/508 nodes are available
Insufficient gpu
Insufficient memory
untolerated taint
```

### Explanation

The requested resources may not currently be available.

Common causes:

- A100 GPUs fully occupied
- RAM request too high
- CPU request too high
- image/node taint mismatch
- GPU type too restrictive

### Fix

Try reducing resource requests:

```text
GPU: 1
GPU Type: L40 or Any
CPU: 4
RAM: 32 GB
```

Or wait for A100 nodes to become available.

---

## GitLab Registry Pull Issues

### Symptom

Kubernetes cannot pull the image.

### Possible Causes

- private GitLab registry project
- missing image pull secret
- incorrect image path
- authentication issue
- image tag does not exist

### Correct Image Path

```text
gitlab-registry.nrp-nautilus.io/centerpoint-research/centerpoint-tide:v1
```

### Fix

Ask the namespace or TIDE administrator to verify:

- registry access
- image pull secret
- image path
- project permissions
- tag availability

---

## OpenPCDet Directory Not Found

### Symptom

```text
ERROR: OpenPCDet directory not found
```

### Explanation

The compile script expects OpenPCDet at the default path configured in the script.

### Fix

Run with an explicit path:

```bash
OPENPCDET_DIR=/path/to/OpenPCDet bash scripts/compile_openpcdet.sh
```

---

## Recommended Diagnostic Commands

Run these when debugging a pod:

```bash
nvidia-smi
```

```bash
which python
python --version
```

```bash
python -c "import torch; print(torch.__version__, torch.version.cuda, torch.cuda.is_available())"
```

```bash
which nvcc
nvcc --version
```

```bash
echo $CUDA_HOME
```

```bash
python -c "import spconv"
```

```bash
python -c "import pcdet"
```

---

## Summary

Most issues fall into one of four categories:

1. The pod image does not include the CUDA Toolkit.
2. The active Conda environment is not the expected one.
3. The Kubernetes/JupyterHub workflow is being confused with local Docker usage.
4. Storage or registry permissions are not configured for the namespace.

When debugging, always verify:

```text
GPU visibility
CUDA Toolkit availability
PyTorch CUDA compatibility
SpConv import
OpenPCDet import
storage location
active Conda environment
```
