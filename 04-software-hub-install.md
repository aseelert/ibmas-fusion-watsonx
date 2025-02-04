# IBM Software Hub Installation

<div align="center">

[![IBM Software Hub](https://img.shields.io/badge/IBM%20Software%20Hub-5.1-054ADA?style=for-the-badge&logo=ibm)](https://www.ibm.com/docs/en/software-hub/5.1.x)
[![OpenShift](https://img.shields.io/badge/OpenShift-4.12+-EE0000?style=for-the-badge&logo=redhat)](https://docs.openshift.com/container-platform/4.12/welcome/index.html)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)

</div>

This guide covers the installation of IBM Software Hub 5.1 core components.

## Prerequisites
Ensure you have completed:
1. [Workstation Preparation](02-workstation-prep.md)
2. [Cluster Preparation](03-cluster-prep.md)

## Installation Steps

### 1. Create Required Projects
```bash
# Create projects for operators and operands
oc new-project ${PROJECT_CPD_INST_OPERATORS}
oc new-project ${PROJECT_CPD_INST_OPERANDS}

# Create projects for shared services
oc new-project ${PROJECT_LICENSE_SERVICE}
oc new-project ${PROJECT_SCHEDULING_SERVICE}
oc new-project ${PROJECT_PRIVILEGED_MONITORING_SERVICE}
```

### 2. Configure Global Pull Secret
```bash
cpd-cli manage add-icr-cred-to-global-pull-secret \
--entitled_registry_key=${IBM_ENTITLEMENT_KEY}
```
⚠️ Note: All nodes will be updated, login to ocp (accept untrusted certificates) and wait for the upgrade (READYMACHINECOUNT should be equals to your workers total):

Ensure the nodes are ready by checking node status with:
```bash
cpd-cli manage oc get nodes
```

### 3. Install Core Components
Apply license service (~3min):
```bash
# Install cluster components
cpd-cli manage apply-cluster-components \
--release=${VERSION} \
--license_acceptance=true \
--licensing_ns=${PROJECT_LICENSE_SERVICE}
```
Apply scheduler (~3min):
```bash
# Setup scheduler
cpd-cli manage apply-scheduler \
--release=${VERSION} \
--license_acceptance=true \
--scheduler_ns=${PROJECT_SCHEDULING_SERVICE}
```

### 4. Configure Instance Topology
Apply the necessary rights to it (~2min):
```bash
# Authorize instance topology
cpd-cli manage authorize-instance-topology \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

Setup the projects (~20min)
```bash
# Setup main instance
cpd-cli manage setup-instance \
--release=${VERSION} \
--license_acceptance=true \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--run_storage_tests=true
```

Get admin user passowrd
```bash
cpd-cli manage get-cpd-instance-details \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--get_admin_initial_credentials=true
```

Install all Components operators (Db2, Watsonx, etc) (~20min):
```bash
# Install Operator Lifecycle Manager
cpd-cli manage apply-olm \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--components=${COMPONENTS}
```

### 6. Configure Monitoring Services
```bash
cpd-cli manage apply-privileged-monitoring-service \
--privileged_service_ns=${PROJECT_PRIVILEGED_MONITORING_SERVICE} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

### 7. Install Configuration Controllers
```bash
# Install and enable config admission controller
cpd-cli manage install-cpd-config-ac \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```
```bash
cpd-cli manage enable-cpd-config-ac \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

## Verification Steps

### 1. Check Custom Resource Status
```bash
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

### 2. Verify Operator Health
```bash
cpd-cli health operators \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--control_plane_ns=${PROJECT_CPD_INST_OPERANDS}
```

### 3. Check Operand Status
```bash
cpd-cli health operands \
--control_plane_ns=${PROJECT_CPD_INST_OPERANDS}
```

### 4. Verify Storage Configuration
```bash
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS}
```

## Troubleshooting

### Common Issues

1. **Pull Secret Issues**
   ```bash
   oc get secret/pull-secret -n openshift-config -o yaml
   ```

2. **Storage Problems**
   ```bash
   oc get pv,pvc -A
   oc describe pvc <pvc-name> -n ${PROJECT_CPD_INST_OPERANDS}
   ```

3. **Operator Status**
   ```bash
   oc get csv -n ${PROJECT_CPD_INST_OPERATORS}
   oc get pods -n ${PROJECT_CPD_INST_OPERATORS}
   ```

## Next Steps
Once Software Hub is installed and verified, proceed to [watsonx Services Installation](05-watsonx-install.md).
