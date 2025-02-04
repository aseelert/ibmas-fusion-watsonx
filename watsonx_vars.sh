#===============================================================================
# Cloud Pak for Data installation variables
#===============================================================================
#------------------------------------------------------------------------------
# Client workstation
#------------------------------------------------------------------------------
# Set the following variables if you want to override the default behaviorof the Cloud Pak for Data CLI.
#
# To export these variables, you must uncomment each command in this sec-tion.
#export watsonx_CLI_MANAGE_WORKSPACE=<enter a fully qualified directory>
# following lines could be used for environment with self-signed certificates and hostnames not resolved by DNS server
#export OLM_UTILS_LAUNCH_ARGS="-v ./api-wxai.pem:/etc/k8scert --env K8S_AUTH_SSL_CA_CERT=/etc/k8scert --add-host oauth-openshift.apps.ocpinstall.gym.lan:192.168.252.4 --add-host api.ocpinstall.gym.lan:192.168.252.3"

#-----------------------------------------------------------------------------
# Cluster
#------------------------------------------------------------------------------
export OCP_USERNAME="kubeadmin"
export OCP_PASSWORD="WMHae-HzW"
export CPD_CLI_MANAGE_WORKSPACE=/home/watsonx
export OCP_URL=https://api.675c27d0b75e66c49dc8f
export OPENSHIFT_TYPE=self-managed
export IMAGE_ARCH=amd64
export SERVER_ARGUMENTS="--server=${OCP_URL}"
#export LOGIN_ARGUMENTS="--token=${OCP_TOKEN}"
export LOGIN_ARGUMENTS="--username  ${OCP_USERNAME} --password ${OCP_PASSWORD}"
export CPDM_OC_LOGIN="cpd-cli manage login-to-ocp ${SERVER_ARGUMENTS} ${LOGIN_ARGUMENTS}"
export OC_LOGIN="oc login ${SERVER_ARGUMENTS} ${LOGIN_ARGUMENTS}"


#------------------------------------------------------------------------------
# Projects
#------------------------------------------------------------------------------
export PROJECT_MANAGEMENT_SERVICE=watsonx-software-hub
export PROJECT_PRIVILEGED_MONITORING_SERVICE=watsonx-software-hub-priv
export PROJECT_CERT_MANAGER=ibm-cert-manager
export PROJECT_LICENSE_SERVICE=ibm-licensing
export PROJECT_SCHEDULING_SERVICE=ibm-cpd-scheduler
export PROJECT_CPD_INST_OPERATORS=watsonx-operators
export PROJECT_CPD_INST_OPERANDS=watsonx-instance
#------------------------------------------------------------------------------
# Storage Fusion
#------------------------------------------------------------------------------
#IBM Storage Fusion Data Foundation: ocs-storagecluster-ceph-rbd
#IBM Storage Fusion Global Data Platform: Either of the following storage classes, depending on your environment:
# -- ibm-spectrum-scale-sc
# -- ibm-storage-fusion-cp-sc
# IBM Storage Scale Container Native: ibm-spectrum-scale-sc
export STG_CLASS_BLOCK=watsonx-default-storage
export STG_CLASS_FILE=watsonx-default-storage

#------------------------------------------------------------------------------
# IBM Entitled Registry
#------------------------------------------------------------------------------
export IBM_ENTITLEMENT_KEY="eyJ0eXAiOiJKV1Qi"
#------------------------------------------------------------------------------
# Cloud Pak for Data version
#------------------------------------------------------------------------------
export VERSION=5.1.0
#------------------------------------------------------------------------------
# Components
#------------------------------------------------------------------------------
#### When you install watsonx.ai, the following services are automatically installed: Watson Studio (ws) and Watson Machine Learning (wml)
#### When you install watsonx.governance, the following services are automatically installed: Watson Machine Learning (wml)
#export COMPONENTS=ibm-licensing,ibm-cert-manager,cpfs,scheduler,watsonx_ai,watsonx_governance,wca_z
export COMPONENTS=ibm-licensing,ibm-cert-manager,cpfs,scheduler

#===============================================================================
# IBM Software Hub Control Center installation variables
#===============================================================================


# ------------------------------------------------------------------------------
# Control Center cluster
# ------------------------------------------------------------------------------

export CONTROL_OCP_URL=${OCP_URL}
export CONTROL_IMAGE_ARCH=${IMAGE_ARCH}
export CONTROL_OCP_USERNAME=${OCP_USERNAME}
export CONTROL_OCP_PASSWORD=${OCP_PASSWORD}
# export CONTROL_OCP_TOKEN=${OCP_TOKEN}
export CONTROL_SERVER_ARGUMENTS="--server=${CONTROL_OCP_URL}"
export CONTROL_LOGIN_ARGUMENTS="--username=${CONTROL_OCP_USERNAME} --password=${CONTROL_OCP_PASSWORD}"
# export CONTROL_LOGIN_ARGUMENTS"--token=${CONTROL_OCP_TOKEN}"
export CONTROL_CPDM_OC_LOGIN="cpd-cli manage login-to-ocp ${CONTROL_SERVER_ARGUMENTS} ${CONTROL_LOGIN_ARGUMENTS}"
export CONTROL_OC_LOGIN="oc login ${CONTROL_SERVER_ARGUMENTS} ${CONTROL_LOGIN_ARGUMENTS}"

# ------------------------------------------------------------------------------
# Control Center storage
# ------------------------------------------------------------------------------

export CONTROL_STG_CLASS_BLOCK=${STG_CLASS_BLOCK}
export CONTROL_STG_CLASS_FILE=${STG_CLASS_FILE}

# ------------------------------------------------------------------------------
# Control Center projects
# ------------------------------------------------------------------------------

export CONTROL_PROJECT_OPERATORS=ibm-control-center-operators
export CONTROL_PROJECT_OPERANDS=ibm-control-center-instance
export CONTROL_PROJECT_LICENSE_SERVICE=${PROJECT_LICENSE_SERVICE}
export CONTROL_PROJECT_SCHEDULING_SERVICE=${PROJECT_SCHEDULING_SERVICE}