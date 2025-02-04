# Cluster Preparation

<div align="center">

[![OpenShift](https://img.shields.io/badge/OpenShift-4.12+-EE0000?style=for-the-badge&logo=redhat)](https://docs.openshift.com/container-platform/4.12/welcome/index.html)
[![NVIDIA](https://img.shields.io/badge/NVIDIA%20GPU-Operator-76B900?style=for-the-badge&logo=nvidia)](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/openshift/contents.html)
[![Storage](https://img.shields.io/badge/Storage-Fusion%20HCI-054ADA?style=for-the-badge&logo=ibm)](https://www.ibm.com/products/storage)

</div>

This guide covers the preparation of your OpenShift cluster for IBM Software Hub and watsonx services installation, including GPU operator setup and storage configuration.

## Cluster Requirements

### Hardware Configuration
- **Master Nodes**: 3 nodes
  - 8 CPU cores per node
  - 32GB RAM per node
  - 120GB storage per node

- **Worker Nodes**: 3 standard + 1 GPU node
  - Standard Workers:
    - 16 CPU cores per node
    - 64GB RAM per node
    - 200GB storage per node
  - GPU Worker:
    - 32 CPU cores
    - 128GB RAM
    - 500GB storage
    - 8 NVIDIA GPUs

### Storage Requirements
- Fusion HCI properly configured
- Storage classes supporting:
  - ReadWriteOnce (RWO)
  - ReadWriteMany (RWX)

## Prerequisites

### Software Requirements
The following operators are required for watsonx.ai and other AI workloads:

| Service | Required Operators |
|---------|-------------------|
| watsonx.ai | - Node Feature Discovery Operator<br>- NVIDIA GPU Operator<br>- Red Hat OpenShift AI |
| Watson Machine Learning | - Node Feature Discovery Operator (for GPU features)<br>- NVIDIA GPU Operator (for GPU features) |
| Watson Studio Runtimes | - Node Feature Discovery Operator (for GPU runtimes)<br>- NVIDIA GPU Operator (for GPU runtimes) |

For detailed compatibility information, see [Installing operators for services that require GPUs](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=software-installing-operators-services-that-require-gpus).

## Storage Configuration

<div align="center">

[![NFS](https://img.shields.io/badge/NFS-Storage-FCC624?style=flat-square&logo=linux&logoColor=black)](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=storage-setting-up-dynamic-provisioning)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat-square&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![IBM Storage](https://img.shields.io/badge/IBM%20Storage-Fusion-054ADA?style=flat-square&logo=ibm)](https://www.ibm.com/products/storage)

</div>

### Option A: Fusion HCI Storage (Preferred)
If you are using IBM Storage Fusion HCI System, the `ibm-storage-fusion-cp-sc` storage class is created by default. No additional configuration is required.

### Option B: NFS Storage Setup
If using NFS storage, follow these steps to set up dynamic provisioning:

1. **Install NFS Server** (if not already available)
   ```bash
   # On NFS Server
   sudo dnf install nfs-utils
   sudo systemctl enable --now nfs-server
   ```

2. **Create and Export NFS Share**
   ```bash
   # Create directory
   sudo mkdir -p /export/cpd
   
   # Set permissions
   sudo chmod -R 777 /export/cpd
   
   # Add to exports
   echo "/export/cpd *(rw,sync,no_root_squash)" | sudo tee -a /etc/exports
   
   # Apply exports
   sudo exportfs -ra
   ```

3. **Configure NFS Client Provisioner**
   First, set the required environment variables in your [watsonx_vars.sh](watsonx_vars.sh):
   ```bash
    export NFS_SERVER_LOCATION=10.10.0.40
    export NFS_PATH=/mnt/data/openshift/snowxd1
    export PROJECT_NFS_PROVISIONER=watsonx-nfs-storage
    export NFS_STORAGE_CLASS=watsonx-default-storage
    export NFS_IMAGE=registry.k8s.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
   ```

   Then run the NFS provisioner setup:
   ```bash
   $CPDM_OC_LOGIN

   cpd-cli manage setup-nfs-provisioner \
    --nfs_server=${NFS_SERVER_LOCATION} \
    --nfs_path=${NFS_PATH} \
    --nfs_provisioner_ns=${PROJECT_NFS_PROVISIONER} \
    --nfs_storageclass_name=${NFS_STORAGE_CLASS} \
    --nfs_provisioner_image=${NFS_IMAGE}
   ```

4. **Verify Storage Setup**
   ```bash
   # Check storage class
   oc get sc ${NFS_STORAGE_CLASS}
   
   # Test with PVC
   cat <<EOF | oc apply -f -
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: test-claim
   spec:
     accessModes:
       - ReadWriteMany
     resources:
       requests:
         storage: 1Gi
     storageClassName: ${NFS_STORAGE_CLASS}
   EOF
   
   # Verify PVC
   oc get pvc test-claim
   ```

## GPU Configuration

### 1. Install Node Feature Discovery Operator
Required for GPU support. Follow the detailed instructions in [GPU Operator Setup](gpu-operator-setup.md#1-install-node-feature-discovery-operator).

### 2. Install NVIDIA GPU Operator
Required for GPU support. Follow the detailed instructions in [GPU Operator Setup](gpu-operator-setup.md#2-install-nvidia-gpu-operator).

### 3. Install NVIDIA GPU Dashboard (Optional)
Optional monitoring dashboard. Follow the detailed instructions in [GPU Operator Setup](gpu-operator-setup.md#3-install-nvidia-gpu-dashboard-optional).

## Security Context Constraints (SCC)

### 1. Create Db2 Kubelet
```bash
# Apply DB2 kubelet configuration
cpd-cli manage apply-db2-kubelet --self_managed=true
```

## DB2 Configuration

### Configure DB2 Privileges
```bash
oc new-project ${PROJECT_CPD_INST_OPERATORS}
# Set DB2 privileges
oc apply -f - <<EOF
apiVersion: v1
data:
  DB2U_RUN_WITH_LIMITED_PRIVS: "false"
kind: ConfigMap
metadata:
  name: db2u-product-cm
  namespace: ${PROJECT_CPD_INST_OPERATORS}
EOF

```

## Kernel Parameters

### 1. Process IDs Limit
```bash
oc apply -f - <<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: KubeletConfig
metadata:
  name: cpd-kubeletconfig
spec:
  kubeletConfig:
    podPidsLimit: 16384
    maxPods: 250 #for SNO use more like 500
  machineConfigPoolSelector:
    matchExpressions:
    - key: pools.operator.machineconfiguration.openshift.io/worker
      operator: Exists
EOF
```

### 2. Power Settings
On **PowerVM capable systems**, you must change the simultaneous multithreading (SMT) settings.
https://www.ibm.com/docs/en/software-hub/5.1.x?topic=settings-changing-power

⚠️ **Important Notes:**
1. After applying kernel parameters or machine configs, worker nodes will need to be rebooted
2. Monitor MCP status:
   ```bash
   oc get mcp
   ```
3. Wait for all nodes to be ready:
   ```bash
   oc get nodes
   ```

## Verification Steps

### 1. Verify GPU Operator Installation
```bash
oc get pods -n nvidia-gpu-operator
oc get nodes -o json | jq '.items[].metadata.labels | select(."nvidia.com/gpu.present" == "true")'
```

### 2. Verify Storage Classes
```bash
oc get sc
```

### 3. Verify Node Status
```bash
oc get nodes
oc describe node <gpu-node-name>
```

## Next Steps
Once your cluster is properly configured, proceed to [Software Hub Installation](04-software-hub-install.md).
