# Appendix: Alternative Installation Page
https://pages.github.ibm.com/CESC-Infrastructure-Services/Installation-CP4D-WatsonX/#/

# Appendix: Debugging and Verification Commands

## Cluster Health Checks

### Connect to SNO master node
```bash
ssh -i /tmp/ocp/cluster/id_rsa core@192.168.252.11
sudo su -
```

### Basic Cluster Status
```bash
# Check cluster version and health
oc get clusterversion
oc get clusteroperators
oc get nodes
oc adm top nodes

# Check cluster events
oc get events --sort-by='.lastTimestamp' -A

# Check etcd health
oc get pods -n openshift-etcd | grep etcd
oc rsh -n openshift-etcd etcd-<master-node> etcdctl endpoint health
```

### Storage Verification
```bash
# Check storage classes
oc get sc
oc describe sc <storage-class-name>

# Check PVs and PVCs
oc get pv
oc get pvc -A
oc get pvc -A | grep -v Bound  # Show unbound PVCs

# NFS specific checks
showmount -e <nfs-server-ip>
df -h | grep nfs
```

## Hardware Detection and GPU Support

### Node Feature Discovery (NFD)
```bash
# Check NFD operator status
oc get pods -n openshift-nfd
oc get nfd -n openshift-nfd
oc logs -n openshift-nfd -l app=nfd-worker

# View NFD labels
oc get nodes -o json | jq '.items[].metadata.labels | with_entries(select(.key | startswith("feature.node.kubernetes.io")))'
oc describe node | grep -A10 "feature.node.kubernetes.io"

# Check specific features
oc get nodes -l feature.node.kubernetes.io/cpu-cpuid.AVX2="true"
oc get nodes -l feature.node.kubernetes.io/pci-0300_10de.present="true"  # NVIDIA GPUs
```

### NVIDIA GPU Operator
```bash
# Check operator status
oc get pods -n nvidia-gpu-operator
oc get csv -n nvidia-gpu-operator

# Check GPU resources
oc describe node | grep nvidia.com
oc get node -o json | jq '.items[].status.allocatable | select(has("nvidia.com/gpu"))'

# GPU pod status
oc logs -n nvidia-gpu-operator -l app=nvidia-driver-daemonset
oc logs -n nvidia-gpu-operator -l app=nvidia-container-toolkit-daemonset

# Test GPU availability
cat <<EOF | oc create -f -
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vector-add
spec:
  restartPolicy: OnFailure
  containers:
    - name: cuda-vector-add
      image: "nvidia/samples:vectoradd-cuda11.2.1"
      resources:
        limits:
          nvidia.com/gpu: 1
EOF

oc logs cuda-vector-add
```

## System Resource Monitoring

### CPU Information
```bash
# Check CPU details
lscpu
cat /proc/cpuinfo
lstopo

# CPU performance
top -1
mpstat -P ALL
vmstat 1 5

# Power management
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### Memory Status
```bash
# Memory usage
free -h
cat /proc/meminfo
vmstat -s
numactl --hardware

# Memory pressure
cat /proc/pressure/memory
sar -r 1 5
```

### GPU Status
```bash
# NVIDIA specific
nvidia-smi
nvidia-smi -q
nvidia-smi topo -m
nvidia-smi pmon -s um
nvidia-debugdump -l

# Check CUDA
nvcc --version
/usr/local/cuda/bin/cuda-install-samples-11.8.0.sh ~
cd ~/NVIDIA_CUDA-11.8_Samples/1_Utilities/deviceQuery
make
./deviceQuery
```

## OpenShift AI and watsonx Components

### OpenShift AI Operator
```bash
# Check operator status
oc get csv -n redhat-ods-operator
oc get pods -n redhat-ods-operator

# Check custom resources
oc get odh
oc get notebooks -A
oc get datascienceclusters -A
```

### DB2 Status
```bash
# Check DB2 pods
oc get pods -n ${PROJECT_CPD_INST_OPERANDS} | grep db2
oc describe pod -n ${PROJECT_CPD_INST_OPERANDS} db2u-0

# Check DB2 logs
oc logs -n ${PROJECT_CPD_INST_OPERANDS} db2u-0 -c db2u
oc exec -it -n ${PROJECT_CPD_INST_OPERANDS} db2u-0 -- su - db2inst1 -c "db2 list applications"
```

### Security Context
```bash
# Check SCCs
oc get scc
oc describe scc db2u-scc
oc describe scc cpd-user-scc

# Check service accounts
oc get sa -n ${PROJECT_CPD_INST_OPERANDS}
oc get rolebindings -n ${PROJECT_CPD_INST_OPERANDS}
```

## Network Verification

### DNS and Connectivity
```bash
# DNS resolution
dig +short api.<cluster-name>.<base-domain>
dig +short *.apps.<cluster-name>.<base-domain>

# Network policies
oc get networkpolicy -A
oc describe networkpolicy -n ${PROJECT_CPD_INST_OPERANDS}

# Service mesh (if installed)
oc get smcp -A
oc get smmr -A
```

### Registry Access
```bash
# Check registry status
oc get configs.imageregistry.operator.openshift.io
oc get pods -n openshift-image-registry

# Test pull access
oc debug node/<node-name> -- chroot /host podman pull registry.redhat.io/openshift4/ose-cli:latest
```

## Troubleshooting Tips

1. **Pod Issues**:
   ```bash
   # Get pod details
   oc describe pod <pod-name> -n <namespace>

   # Get previous pod logs
   oc logs <pod-name> -n <namespace> --previous

   # Check pod events
   oc get events -n <namespace> --sort-by='.lastTimestamp'
   ```

2. **Node Issues**:
   ```bash
   # Check node conditions
   oc describe node | grep -A5 Conditions

   # Check node capacity
   oc describe node | grep -A5 Capacity

   # Check node pressure
   oc describe node | grep -A5 Pressure
   ```

3. **Resource Issues**:
   ```bash
   # Check resource quotas
   oc get resourcequota -A

   # Check limit ranges
   oc get limitrange -A

   # Check pod resource usage
   oc adm top pods -A
   ```

⚠️ **Note**:
- Some commands require elevated privileges
- Adjust namespace names according to your installation
- GPU commands require NVIDIA drivers and tools
- Some commands might need to be run directly on the nodes
