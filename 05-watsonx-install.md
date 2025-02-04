# watsonx Services Installation

<div align="center">

[![watsonx.ai](https://img.shields.io/badge/watsonx.ai-2.1-BE95FF?style=for-the-badge&logo=ibm)](https://www.ibm.com/products/watsonx-ai)
[![watsonx.governance](https://img.shields.io/badge/watsonx.governance-2.1-BE95FF?style=for-the-badge&logo=ibm)](https://www.ibm.com/products/watsonx-governance)
[![watsonx Code Assistant for Z](https://img.shields.io/badge/watsonx_Code_Assistant_for_Z-2.x-BE95FF?style=flat-square&logo=ibm)](https://www.ibm.com/docs/en/watsonx/watsonx-code-assistant-4z/2.1?topic=welcome-infrastructure-requirements)
[![NVIDIA](https://img.shields.io/badge/NVIDIA%20GPU-Operator-76B900?style=for-the-badge&logo=nvidia)](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/openshift/contents.html)

</div>

This guide covers the installation of watsonx.ai and watsonx.governance services on IBM Software Hub 5.1.

## Prerequisites
Ensure you have completed:
1. [Workstation Preparation](02-workstation-prep.md)
2. [Cluster Preparation](03-cluster-prep.md)
3. [Software Hub Installation](04-software-hub-install.md)

## Pre-Installation Steps

### 1. Verify GPU Support
```bash
# Check GPU operator status
oc get pods -n nvidia-gpu-operator

# Verify GPU detection
oc get nodes -o json | jq '.items[].metadata.labels | select(."nvidia.com/gpu.present" == "true")'
```

### 2. Apply Service Entitlements
```bash
# Apply watsonx.ai entitlement
cpd-cli manage apply-entitlement \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--entitlement=watsonx-ai
```
```bash
# Apply watsonx.governance entitlements
cpd-cli manage apply-entitlement \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--entitlement=watsonx-gov-mm
```
```bash
cpd-cli manage apply-entitlement \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--entitlement=watsonx-gov-rc
```

## Installation Steps

### 1. Create Installation Options File
```bash
cat <<EOF > ${CPD_CLI_MANAGE_WORKSPACE}/work/install-options.yml
custom_spec:
  watsonx_ai:
    tuning_disabled: false
    lite_install: false
  watsonx_governance:
    installType: all
    enableFactsheet: true
    enableOpenpages: true
    enableOpenscale: true
EOF
```

### 2. Install Components

Choose one of the following options based on your requirements:

#### Option A: Install Both watsonx.ai and watsonx.governance
This install can take up to 1-3 hours.
```bash
cpd-cli manage apply-cr \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=${COMPONENTS} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true \
--param-file=/tmp/work/install-options.yml
```

#### Option B: Install watsonx.governance Only
This install can take up to 1 hour (~64min).
```bash
cpd-cli manage apply-cr \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=watsonx_governance \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true \
--param-file=/tmp/work/install-options.yml
```

## Post-Installation Configuration

### 1. GPU Settings Configuration

#### For Clusters with GPUs (Default)
No additional configuration is needed. The default settings will utilize the available GPUs for watsonx.ai workloads.

#### For Clusters without GPUs (e.g., Single Node OpenShift)
If you're running on a cluster **without GPUs**, you need to disable GPU tuning:
```bash
oc patch watsonxai watsonxai-cr \
--namespace=${PROJECT_CPD_INST_OPERANDS} \
--type=merge \
--patch='{"spec":{"tuning_disabled": true}}'
```

Adapt the following patch command to deploy the llama-2-13b-chat model and don't forget to specify the right namespace and model ID:
```bash
oc patch watsonxaiifm watsonxaiifm-cr \
--namespace=${PROJECT_CPD_INST_OPERANDS} \
--type=merge \
--patch='{"spec":{"install_model_list": ["<your-model-id>"]}}'
```

Check the progress of the deployment with:
```bash
oc get watsonxaiifm
```

**Optional**: If you want to add more models, you can patch the instance again, you just need to augment the list with new models (ensure existing one are in the list), eg:
```bash
oc patch watsonxaiifm watsonxaiifm-cr \
--namespace=${PROJECT_CPD_INST_OPERANDS} \
--type=merge \
--patch='{"spec":{"install_model_list": ["ibm-granite-13b-instruct-v1","google-flan-ul2"]}}'
```



### 2. Get Admin Credentials
```bash
cpd-cli manage get-cpd-instance-details \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--get_admin_initial_credentials=true
```

## Verification Steps

### 1. Check Service Status
```bash
# Check custom resources
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```
```bash
# Check operands
cpd-cli health operands \
--control_plane_ns=${PROJECT_CPD_INST_OPERANDS}
```

### 2. Verify GPU Access
```bash
# Check GPU pods
oc get pods -n ${PROJECT_CPD_INST_OPERANDS} | grep gpu

# Check GPU allocation
oc describe node <gpu-node-name> | grep -A5 Allocated
```

### 3. Access Web Console
1. Get the console URL:
   ```bash
   oc get route -n ${PROJECT_CPD_INST_OPERANDS} cpd -o jsonpath='{.spec.host}'
   ```
2. Access the URL in a browser
3. Login with admin credentials obtained earlier

## Troubleshooting

### Common Issues

1. **GPU Detection Issues**
   ```bash
   oc logs -n nvidia-gpu-operator <nvidia-device-plugin-pod>
   oc describe node <gpu-node-name>
   ```

2. **Service Startup Problems**
   ```bash
   oc get events -n ${PROJECT_CPD_INST_OPERANDS}
   oc logs -n ${PROJECT_CPD_INST_OPERANDS} <pod-name>
   ```

3. **Storage Issues**
   ```bash
   oc get pvc -n ${PROJECT_CPD_INST_OPERANDS}
   oc describe pvc <pvc-name> -n ${PROJECT_CPD_INST_OPERANDS}
   ```

## Next Steps
If required, proceed to [Control Center Installation](06-control-center-install.md).
