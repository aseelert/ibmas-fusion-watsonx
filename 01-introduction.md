# IBM Software Hub 5.1 with watsonx Installation Guide

<div align="center">

[![IBM Software Hub](https://img.shields.io/badge/IBM%20Software%20Hub-5.1-054ADA?style=for-the-badge&logo=ibm)](https://www.ibm.com/docs/en/software-hub/5.1.x)
[![OpenShift](https://img.shields.io/badge/OpenShift-4.12+-EE0000?style=for-the-badge&logo=redhat)](https://docs.openshift.com/container-platform/4.12/welcome/index.html)
[![Storage](https://img.shields.io/badge/Storage-Fusion%20HCI-054ADA?style=for-the-badge&logo=ibm)](https://www.ibm.com/products/storage)

</div>

## Overview
This guide provides comprehensive instructions for installing IBM Software Hub 5.1 with watsonx.ai and watsonx.governance services on a Fusion HCI-based OpenShift cluster. Our setup is specifically designed for high-performance AI workloads with dedicated GPU support.

## Architecture Overview

### Cluster Configuration
- **Master Nodes**: 3 nodes for high availability
- **Worker Nodes**: 4 nodes total
  - 3 standard worker nodes
  - 1 specialized GPU worker node with 8 NVIDIA GPUs

### Storage Infrastructure
- **Platform**: IBM Storage Fusion HCI
- **Storage Classes**:
  - Block Storage (RWO)
  - File Storage (RWX)

### Components to be Installed
<div align="center">

[![watsonx.ai](https://img.shields.io/badge/watsonx.ai-2.1-BE95FF?style=flat-square&logo=ibm)](https://www.ibm.com/products/watsonx-ai)
[![watsonx.governance](https://img.shields.io/badge/watsonx.governance-2.1-BE95FF?style=flat-square&logo=ibm)](https://www.ibm.com/products/watsonx-governance)
[![watsonx Code Assistant for Z](https://img.shields.io/badge/watsonx_Code_Assistant_for_Z-2.x-BE95FF?style=flat-square&logo=ibm)](https://www.ibm.com/docs/en/watsonx/watsonx-code-assistant-4z/2.1?topic=welcome-infrastructure-requirements)
[![NVIDIA](https://img.shields.io/badge/NVIDIA%20GPU-Operator-76B900?style=flat-square&logo=nvidia)](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/openshift/contents.html)

</div>

1. **IBM Software Hub 5.1**
   - Core platform services
   - Management components
   - Monitoring and logging

2. **watsonx.ai**
   - Foundation models
   - AI workload management
   - GPU-accelerated inference
   - Prompt lab and experimentation tools

3. **watsonx.governance**
   - AI governance framework
   - Model lifecycle management
   - Compliance and audit capabilities
   - Integration with watsonx.ai

4. **Optional: Control Center**
   - Centralized management interface
   - Multi-cluster visibility
   - Resource monitoring

5. **Watsonx Code Assistant for Z**
   - wca_z component for Code Assistant
   - https://www.ibm.com/docs/en/software-hub/5.1.x?topic=z-installing
   - https://www.ibm.com/docs/en/watsonx/watsonx-code-assistant-4z/2.x?topic=welcome-infrastructure-requirements

## Installation Flow
1. [Workstation Preparation](02-workstation-prep.md)
2. [Cluster Preparation](03-cluster-prep.md)
3. [Software Hub Installation](04-software-hub-install.md)
4. [watsonx Services Installation](05-watsonx-install.md)
5. [Control Center Installation](06-control-center-install.md) (Optional)

## Prerequisites Overview
<div align="center">

[![OpenShift](https://img.shields.io/badge/OpenShift-4.12+-EE0000?style=flat-square&logo=redhat)](https://docs.openshift.com/container-platform/4.12/welcome/index.html)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat-square&logo=docker&logoColor=white)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat-square&logo=kubernetes&logoColor=white)](https://kubernetes.io/)

</div>

- OpenShift Container Platform 4.12 or later
- IBM Entitlement Key
- Network connectivity to IBM Container Registry
- Fusion HCI storage system properly configured
- NVIDIA GPU drivers and support

## Hardware Infrastructure
- **Compute**: OpenShift worker nodes with minimum 32 vCPU and 128GB RAM per node
- **Storage**: IBM Storage Fusion HCI or equivalent storage solution
- **GPU**: NVIDIA A100 or equivalent (optional, but recommended for watsonx.ai)
- **Network**: 10GbE minimum, 25GbE recommended

## Software Components
1. **Base Platform**
   - Red Hat OpenShift Container Platform 4.12+
   - IBM Storage Fusion HCI 3.3+
   - NVIDIA GPU Operator (for GPU support)

2. **Core Services**
   - IBM Software Hub 5.1
   - IBM Licensing Service
   - IBM Scheduling Service
   - IBM DB2 Universal Database

3. **watsonx Services**
   - watsonx.ai
   - watsonx.governance
   - watsonx.data (optional)
   - watsonx Code Assistant for Z

4. **Optional Components**
   - Control Center
   - Red Hat OpenShift AI
   - IBM Watson Studio

## Prerequisites

### OpenShift Requirements
- OpenShift Container Platform 4.12 or later
- Cluster admin privileges
- Access to OpenShift image registry
- Valid IBM entitlement key

### Hardware Requirements

#### Minimum Node Specifications
| Component | CPU | Memory | Storage |
|-----------|-----|---------|----------|
| Control Plane | 8 vCPU | 32GB | 120GB |
| Worker Node | 32 vCPU | 128GB | 200GB |
| GPU Node* | 32 vCPU | 256GB | 200GB |

\* Required for watsonx.ai with GPU support

#### Storage Requirements
| Component | Size | Storage Class | Access Mode |
|-----------|------|---------------|-------------|
| IBM Software Hub | 500GB | block | RWO |
| watsonx.ai | 2TB | block | RWO |
| watsonx.governance | 1TB | block | RWO |
| DB2 | 500GB | block | RWO |

### Network Requirements
- Outbound internet access for image pulls
- DNS resolution for cluster domains
- Load balancer for API and ingress traffic
- Network policies allowing inter-namespace communication

### Security Requirements
- TLS certificates for secure communication
- Security Context Constraints (SCC) configuration
- Network policies for namespace isolation
- Valid IBM entitlement key

### Additional Requirements
- IBM Cloud Pak CLI (cpd-cli)
- OpenShift CLI (oc)
- NVIDIA drivers and toolkit (for GPU nodes)
- Access to required image registries:
  - registry.redhat.io
  - cp.icr.io
  - docker.io

## Quick Links
- [IBM Software Hub Documentation](https://www.ibm.com/docs/en/software-hub/5.1.x)
- [OpenShift Documentation](https://docs.openshift.com/)
- [watsonx Documentation](https://www.ibm.com/docs/en/watsonx-as-a-service)
- [NVIDIA GPU Operator Guide](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/openshift/contents.html)

## Support
For support and troubleshooting:
- [IBM Support Portal](https://www.ibm.com/support/home/)
- [Red Hat Support](https://access.redhat.com/support)
- [NVIDIA Support](https://www.nvidia.com/en-us/support/)
