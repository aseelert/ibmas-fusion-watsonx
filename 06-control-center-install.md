# Control Center Installation (Optional)

<div align="center">

[![IBM Software Hub](https://img.shields.io/badge/Control%20Center-5.1-054ADA?style=for-the-badge&logo=ibm)](https://www.ibm.com/docs/en/software-hub/5.1.x)
[![OAuth](https://img.shields.io/badge/OAuth-2.0-43853d?style=for-the-badge&logo=oauth&logoColor=white)](https://oauth.net/2/)
[![Security](https://img.shields.io/badge/Security-Enabled-success?style=for-the-badge&logo=vault&logoColor=white)](https://www.ibm.com/security)

</div>

This guide covers the optional installation of the IBM Software Hub Control Center, which provides centralized management capabilities.

## Prerequisites
Ensure you have completed:
1. [Software Hub Installation](04-software-hub-install.md)
2. [watsonx Services Installation](05-watsonx-install.md)

## Installation Steps

### 1. Create Required Projects
```bash
# Create projects for Control Center
oc new-project ${CONTROL_PROJECT_LICENSE_SERVICE}
oc new-project ${CONTROL_PROJECT_SCHEDULING_SERVICE}
oc new-project ${CONTROL_PROJECT_OPERATORS}
oc new-project ${CONTROL_PROJECT_OPERANDS}
```

### 2. Install Core Components
```bash
cpd-cli manage apply-cluster-components \
--release=${VERSION} \
--license_acceptance=true \
--licensing_ns=${CONTROL_PROJECT_LICENSE_SERVICE}
```

### 3. Setup Scheduler
```bash
cpd-cli manage apply-scheduler \
--release=${VERSION} \
--license_acceptance=true \
--scheduler_ns=${CONTROL_PROJECT_SCHEDULING_SERVICE}
```

### 4. Configure Instance
```bash
# Authorize topology
cpd-cli manage authorize-instance-topology \
--cpd_operator_ns=${CONTROL_PROJECT_OPERATORS} \
--cpd_instance_ns=${CONTROL_PROJECT_OPERANDS}

# Setup Control Center instance
cpd-cli manage setup-control-center \
--release=${VERSION} \
--license_acceptance=true \
--operator_ns=${CONTROL_PROJECT_OPERATORS} \
--operand_ns=${CONTROL_PROJECT_OPERANDS} \
--block_storage_class=${CONTROL_STG_CLASS_BLOCK}
```

### 5. Configure OAuth
```bash
export OAUTH_CLIENT_ID=ibm-software-hub-cc
export OAUTH_SECRET=IBM4ever

cat <<EOF | oc apply -f -
kind: OAuthClient
apiVersion: oauth.openshift.io/v1
metadata:
  name: ${OAUTH_CLIENT_ID}
secret: ${OAUTH_SECRET}
redirectURIs:
  - 'https://${CONTROL_CENTER_ROUTE}/zen/oauth/redirect'
grantMethod: prompt
accessTokenMaxAgeSeconds: 120
accessTokenInactivityTimeoutSeconds: 300
scopeRestrictions:
  - clusterRole:
      allowEscalation: false
      namespaces:
        - '*'
      roleNames:
        - 'cluster-reader'
EOF
```

### 6. Get CPADMIN password for Control Center
```bash
cpd-cli manage get-cpd-instance-details --cpd_instance_ns=${CONTROL_PROJECT_OPERANDS} --get_admin_initial_credentials=true
```

## Verification Steps

### 1. Check Installation Status
```bash
# Verify operators
cpd-cli health operators \
--operator_ns=${CONTROL_PROJECT_OPERATORS} \
--control_plane_ns=${CONTROL_PROJECT_OPERANDS}
```
```bash
# Check operands
cpd-cli health operands \
--control_plane_ns=${CONTROL_PROJECT_OPERANDS}
```

### 2. Access Control Center
1. Get the route:
   ```bash
   oc get route -n ${CONTROL_PROJECT_OPERANDS} cpd -o jsonpath='{.spec.host}'
   ```
2. Access the URL in a browser
3. Login with OpenShift credentials

## Troubleshooting

### Common Issues

1. **OAuth Issues**
   ```bash
   oc get oauthclient ${OAUTH_CLIENT_ID}
   oc describe oauthclient ${OAUTH_CLIENT_ID}
   ```

2. **Route Problems**
   ```bash
   oc get route -n ${CONTROL_PROJECT_OPERANDS}
   oc describe route -n ${CONTROL_PROJECT_OPERANDS} cpd
   ```

3. **Pod Status**
   ```bash
   oc get pods -n ${CONTROL_PROJECT_OPERANDS}
   oc describe pod <pod-name> -n ${CONTROL_PROJECT_OPERANDS}
   ```

## Additional Configuration

### 1. Configure LDAP Authentication (Optional)
<div align="center">

[![LDAP](https://img.shields.io/badge/LDAP-Integration-yellow?style=flat-square&logo=openldap&logoColor=white)](https://www.openldap.org/)
[![TLS](https://img.shields.io/badge/TLS-Certificates-success?style=flat-square&logo=letsencrypt&logoColor=white)](https://letsencrypt.org/)
[![SSO](https://img.shields.io/badge/SSO-Authentication-blue?style=flat-square&logo=openid&logoColor=white)](https://openid.net/)

</div>

Follow the [LDAP configuration guide](https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=center-configuring-ldap-authentication) for setting up enterprise authentication.

### 2. Configure TLS Certificates (Optional)
Follow the [TLS configuration guide](https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=center-configuring-custom-tls-certificates) for setting up custom certificates.

## Maintenance

### Backup Procedures
1. Back up OAuth configuration
2. Back up custom configurations
3. Back up any custom certificates

### Updating Control Center
Follow the [update procedures](https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=center-updating) when new versions are available.
