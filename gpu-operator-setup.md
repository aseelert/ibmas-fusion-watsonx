# GPU Operator Setup and Configuration

> **Note**: This guide covers the installation of all GPU-related components required for watsonx.ai, including Node Feature Discovery, NVIDIA GPU Operator, and Red Hat OpenShift AI.

<div align="center">

[![NVIDIA](https://img.shields.io/badge/NVIDIA%20GPU-Operator-76B900?style=for-the-badge&logo=nvidia)](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/openshift/contents.html)
[![OpenShift](https://img.shields.io/badge/OpenShift-4.12+-EE0000?style=for-the-badge&logo=redhat)](https://docs.openshift.com/)
[![OpenShift AI](https://img.shields.io/badge/OpenShift-AI-EE0000?style=for-the-badge&logo=redhat)](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=software-installing-red-hat-openshift-ai)

</div>

## Prerequisites

- OpenShift 4.12+
- NVIDIA GPU hardware
- Cluster administrator access
- IBM entitlement key for watsonx.ai

## Version Compatibility Matrix

| Component | Required Version | Notes |
|-----------|-----------------|-------|
| OpenShift | 4.12 - 4.17 | Check specific NFD docs for your version |
| NVIDIA GPU Operator | 23.9.2+ | Latest stable recommended |
| OpenShift AI | 2.11+ | Required for watsonx.ai 5.0.3 |
| Node Feature Discovery | Latest stable | Version matches OpenShift |

## Installation Steps

### 1. Install Node Feature Discovery Operator

> **📚 Documentation**:
> - IBM Documentation: [Installing Node Feature Discovery](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=software-installing-operators-services-that-require-gpus)
> - Nvidia Documentation: [Node Feature Discovery Operator](https://docs.nvidia.com/datacenter/cloud-native/openshift/23.9.2/install-nfd.html)

1. Create NFD namespace:
```bash
oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-nfd
EOF
```

2. Create OperatorGroup:
```bash
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  generateName: openshift-nfd-
  name: openshift-nfd
  namespace: openshift-nfd
spec:
  targetNamespaces:
  - openshift-nfd
EOF
```

3. Create Subscription:
```bash
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: nfd
  namespace: openshift-nfd
spec:
  channel: "stable"
  installPlanApproval: Automatic
  name: nfd
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
```

4. Verify NFD pods:
```bash
oc get pods -n openshift-nfd
```

# Create NodeFeatureDiscovery instance
```bash
oc apply -f - <<EOF
apiVersion: nfd.openshift.io/v1
kind: NodeFeatureDiscovery
metadata:
  name: nfd-instance
  namespace: openshift-nfd
spec:
  instance: "" # instance is empty by default
  topologyupdater: false # False by default
  operand:
    image: registry.redhat.io/openshift4/ose-node-feature-discovery:v4.12
    imagePullPolicy: Always
  workerConfig:
    configData: |
      core:
      #  labelWhiteList:
      #  noPublish: false
        sleepInterval: 60s
      #  sources: [all]
      #  klog:
      #    addDirHeader: false
      #    alsologtostderr: false
      #    logBacktraceAt:
      #    logtostderr: true
      #    skipHeaders: false
      #    stderrthreshold: 2
      #    v: 0
      #    vmodule:
      ##   NOTE: the following options are not dynamically run-time configura-ble
      ##         and require a nfd-worker restart to take effect after being changed
      #    logDir:
      #    logFile:
      #    logFileMaxSize: 1800
      #    skipLogHeaders: false
      sources:
        cpu:
          cpuid:
      #     NOTE: whitelist has priority over blacklist
            attributeBlacklist:
              - "BMI1"
              - "BMI2"
              - "CLMUL"
              - "CMOV"
              - "CX16"
              - "ERMS"
              - "F16C"
              - "HTT"
              - "LZCNT"
              - "MMX"
              - "MMXEXT"
              - "NX"
              - "POPCNT"
              - "RDRAND"
              - "RDSEED"
              - "RDTSCP"
              - "SGX"
              - "SSE"
              - "SSE2"
              - "SSE3"
              - "SSE4.1"
              - "SSE4.2"
              - "SSSE3"
            attributeWhitelist:
        kernel:
          kconfigFile: "/path/to/kconfig"
          configOpts:
            - "NO_HZ"
            - "X86"
            - "DMI"
        pci:
          deviceClassWhitelist:
            - "0200"
            - "03"
            - "12"
          deviceLabelFields:
            - "class"
            - "vendor"
  customConfig:
    configData: |
          - name: "more.kernel.features"
            matchOn:
loadedKMod: ["example_kmod3"]
EOF
```

### 2. Install NVIDIA GPU Operator

> **📚 Documentation**:
> - IBM Documentation: [Installing the NVIDIA GPU Operator](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=gpus-installing-nvidia-gpu-operator)
> - NVIDIA Documentation: [GPU Operator on OpenShift](https://docs.nvidia.com/datacenter/cloud-native/openshift/23.9.2/install-gpu-ocp.html)

> **⚠️ Version Check Required**:
> 1. Check available operator versions:
```bash
oc get packagemanifest gpu-operator-certified -n openshift-marketplace -o jsonpath='{.status.channels[*].name}'
```
> 2. Verify compatibility with your OpenShift version in the [NVIDIA compatibility matrix](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/platform-support.html)

1. Create namespace:
```bash
oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: nvidia-gpu-operator
EOF
```

2. Create OperatorGroup:
```bash
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: nvidia-gpu-operator-group
  namespace: nvidia-gpu-operator
spec:
 targetNamespaces:
 - nvidia-gpu-operator
EOF
```

3. Get channel and CSV information:
```bash
# Get default channel
export CHANNEL=$(oc get packagemanifest gpu-operator-certified -n openshift-marketplace -o jsonpath='{.status.defaultChannel}')
```

```bash
# Get current CSV
export CURRENT_CSV=$(oc get packagemanifests/gpu-operator-certified -n openshift-marketplace -ojson | jq -r '.status.channels[] | select(.name == "'$CHANNEL'") | .currentCSV')
```

4. Create subscription:
```bash
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: gpu-operator-certified
  namespace: nvidia-gpu-operator
spec:
  channel: "${CHANNEL}"
  installPlanApproval: Manual
  name: gpu-operator-certified
  source: certified-operators
  sourceNamespace: openshift-marketplace
  startingCSV: "${CURRENT_CSV}"
EOF
```

5. Verify install plan:
```bash
oc get installplan -n nvidia-gpu-operator
```

6. Get install plan name:
```bash
export INSTALL_PLAN=$(oc get installplan -n nvidia-gpu-operator -oname)
```

7. Approve install plan:
```bash
oc patch $INSTALL_PLAN -n nvidia-gpu-operator --type merge --patch '{"spec":{"approved":true }}'
```

8. Create cluster policy:
```bash
# Extract policy template
oc get csv -n nvidia-gpu-operator $CURRENT_CSV -ojsonpath={.metadata.annotations.alm-examples} | jq .[0] > clusterpolicy.json
```

```bash
# Apply policy
oc apply -f clusterpolicy.json
```

### 3. Install Red Hat OpenShift AI

> **📚 Documentation**:
> - IBM Documentation: [Installing Red Hat OpenShift AI](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=software-installing-red-hat-openshift-ai)

> **⚠️ Version Requirements**:
> - Minimum version: 2.11
> - Check available versions:
```bash
oc get packagemanifest rhods-operator -n openshift-marketplace -o jsonpath='{.status.channels[*].name}'
```

1. Create operator project:
```bash
oc new-project redhat-ods-operator
```

1. Create operator group:
```bash
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: rhods-operator
  namespace: redhat-ods-operator
EOF
```

1. Create operator subscription:
```bash
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rhods-operator
  namespace: redhat-ods-operator
spec:
  name: rhods-operator
  channel: stable-2.13
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  config:
    env:
      - name: "DISABLE_DSC_CONFIG"
EOF
```

1. Create DSCInitialization
```bash
cat <<EOF | oc apply -f -
apiVersion: dscinitialization.opendatahub.io/v1
kind: DSCInitialization
metadata:
  name: default-dsci
spec:
  applicationsNamespace: redhat-ods-applications
  monitoring:
    managementState: Managed
    namespace: redhat-ods-monitoring
  serviceMesh:
    managementState: Removed
  trustedCABundle:
    managementState: Managed
    customCABundle: ""
EOF
```

```bash
oc get pods -n redhat-ods-monitoring
oc get dscinitialization
```

5. Create DataScienceCluster
```bash
cat <<EOF | oc apply -f -
apiVersion: datasciencecluster.opendatahub.io/v1
kind: DataScienceCluster
metadata:
  name: default-dsc
spec:
  components:
    codeflare:
      managementState: Removed
    dashboard:
      managementState: Removed
    datasciencepipelines:
      managementState: Removed
    kserve:
      managementState: Managed
      defaultDeploymentMode: RawDeployment
      serving:
        managementState: Removed
        name: knative-serving
    kueue:
      managementState: Removed
    modelmeshserving:
      managementState: Removed
    ray:
      managementState: Removed
    trainingoperator:
      managementState: Managed
    trustyai:
      managementState: Removed
    workbenches:
      managementState: Removed
EOF
```

Verify the installation:
```bash
# Check operator pod status
oc get pods -n redhat-ods-monitoring

# Verify DSCInitialization status
oc get dscinitialization

# Check DataScienceCluster status
oc get datasciencecluster default-dsc -o jsonpath='"{.status.phase}" {"\n"}'

# Verify required pods are running
oc get pods -n redhat-ods-applications
```

> **Note**: After installation, you'll need to configure the `inferenceservice-config` ConfigMap in the `redhat-ods-applications` project:
>
> Log in to the Red Hat OpenShift Container Platform web console as a cluster administrator.
> From the navigation menu, select Workloads > Configmaps.
> From the Project list, select redhat-ods-applications.
> Click the inferenceservice-config resource. Then, open the YAML tab.
> In the metadata.annotations section of the file, add `opendatahub.io/managed: 'false'`:
> ```yaml
> metadata:
>   annotations:
>     internal.config.kubernetes.io/previousKinds: ConfigMap
>     internal.config.kubernetes.io/previousNames: inferenceservice-config
>     internal.config.kubernetes.io/previousNamespaces: opendatahub
>     opendatahub.io/managed: 'false'
> ```
>
> Find the following entry in the file:
> ```yaml
> "domainTemplate": "{{ .Name }}-{{ .Namespace }}.{{ .IngressDomain }}",
> ```
>
> Update the value of the `domainTemplate` field to `example.com`:
> ```yaml
> "domainTemplate": "example.com",
> ```
>
> Click Save.

### 4. Configure MIG (Optional)

> **📚 Documentation**:
> - IBM Documentation: [Configuring NVIDIA MIG](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=gpus-configuring-mig)
> - NVIDIA Documentation: [MIG Support in GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-operator-mig.html)

If you want to partition your GPUs using NVIDIA Multi-Instance GPU (MIG), follow the [MIG configuration guide](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=gpus-configuring-mig).

### 5. Install NVIDIA GPU Dashboard (Optional)

> **📚 Documentation**:
> - IBM Documentation: [Monitoring GPUs](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=gpus-monitoring)
> - Red Hat Documentation: [Using the NVIDIA GPU console plugin](https://docs.openshift.com/container-platform/4.12/monitoring/nvidia-gpu-admin-dashboard.html)

helm setup Install helm Open https://console-openshift-console.apps.poc.watsonx-otc.com/command-line-tools and follow link to download helm -> https://mirror.openshift.com/pub/openshift-v4/clients/helm/latest

```bash
wget https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients/helm/3.12.1/helm-linux-amd64
mv helm-linux-amd64 helm
chmod +x helm
sudo cp helm ~/.local/bin
```

Add the Helm repository:
```bash
# Add Helm repository
helm repo add rh-ecosystem-edge https://rh-ecosystem-edge.github.io/console-plugin-nvidia-gpu
helm repo update
```

Install Helm chart:
```bash
helm install -n nvidia-gpu-operator console-plugin-nvidia-gpu rh-ecosystem-edge/console-plugin-nvidia-gpu
oc -n nvidia-gpu-operator get all -l app.kubernetes.io/name=console-plugin-nvidia-gpu
```

Enable plugin:
```bash
oc get consoles.operator.openshift.io cluster --output=jsonpath="{.spec.plugins}"
oc patch consoles.operator.openshift.io cluster --patch '{ "spec": { "plugins": ["console-plugin-nvidia-gpu"] } }' --type=merge
oc patch consoles.operator.openshift.io cluster --patch '[{"op": "add", "path": "/spec/plugins/-", "value": "console-plugin-nvidia-gpu" }]' --type=json
```

Configure DCGM Exporter metrics:
```bash
oc patch clusterpolicies.nvidia.com gpu-cluster-policy --patch '{ "spec": { "dcgmExporter": { "config": { "name": "console-plugin-nvidia-gpu" } } } }' --type=merge

```

## Verification

### 1. Test GPU Detection
```bash
# Create test pod
cat << EOF | oc create -f -
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vectoradd
spec:
 restartPolicy: OnFailure
 containers:
 - name: cuda-vectoradd
   image: "nvidia/samples:vectoradd-cuda11.2.1"
   resources:
     limits:
       nvidia.com/gpu: 1
EOF

# Check pod logs
oc logs cuda-vectoradd
```

### 2. Verify Operator Status
```bash
# Check NFD status
oc get pods -n openshift-nfd

# Check GPU operator status
oc get pods -n nvidia-gpu-operator

# Verify GPU detection
oc get nodes -o json | jq '.items[].metadata.labels | select(."nvidia.com/gpu.present" == "true")'
```

## Next Steps
Once GPU setup is complete, proceed to [watsonx Services Installation](05-watsonx-install.md).

## References
- [NVIDIA GPU Operator Documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/openshift/contents.html)
- [Node Feature Discovery Documentation](https://docs.openshift.com/container-platform/4.17/hardware_enablement/psap-node-feature-discovery-operator.html)
- [NVIDIA GPU Dashboard Documentation](https://docs.openshift.com/container-platform/4.17/monitoring/nvidia-gpu-admin-dashboard.html)
- [Installing Red Hat OpenShift AI](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=software-installing-red-hat-openshift-ai)
- [Installing Operators for GPU Services](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=software-installing-operators-services-that-require-gpus)
- [Configuring NVIDIA MIG](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=gpus-configuring-mig)
