# Workstation Preparation

<div align="center">

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Red Hat](https://img.shields.io/badge/Red%20Hat-EE0000?style=for-the-badge&logo=redhat&logoColor=white)](https://www.redhat.com/)

</div>

## System Requirements

### Hardware
- 4 CPU cores
- 16GB RAM
- 100GB free disk space

### Software
- RHEL 8.x or equivalent
- Python 3.10+
- OpenSSH client
- Git client

### Network
- Access to OpenShift cluster API
- Access to required registries
- Outbound internet access

## Installation Steps

### 1. Install Base Tools 
```bash
# Install required packages
sudo dnf install -y \
  wget curl git jq \
  python3.12 python3.12-pip \
  yum-utils device-mapper-persistent-data lvm2
```

### Prefered installation **Podman** / free license
##### Add Flatpak for Podman / Rocky / Redhat / Centos install
```bash
# Install podman and enable FlatPak repo
sudo dnf install podman podman-plugins
````

Install Podman Desktop UI
```bash
# Install podman UI via flatpka
sudo dnf install flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub io.podman_desktop.PodmanDesktop
```


### Optional installation **docker** / requires an Enterprise license
##### Add Docker CE repository
```bash
sudo dnf config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker CE
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker installation
docker --version
```


### 2. Create Installation User
Create a dedicated user `watsonx` for managing the installation process:
```bash
# Create user and set password
sudo useradd -m watsonx
sudo passwd watsonx

# Add to necessary groups
sudo usermod -aG docker watsonx  # Only if Docker is needed
sudo usermod -aG wheel watsonx   # Add to sudoers group

# Configure sudo access without password
echo "watsonx ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/watsonx

# Switch to watsonx user
su - watsonx
```

⚠️ **Security Note**: Granting sudo access without password should only be done in controlled environments. Adjust security settings according to your organization's policies.

### 3. Install Required CLIs

Generat local user bases executable dir
```bash
mkdir -p ~/.local/bin/
```

Login as the watsonx user and install the necessary CLI tools:
```bash
# Install IBM Cloud Pak CLI
wget https://github.com/IBM/cpd-cli/releases/download/v14.1.0/cpd-cli-linux-EE-14.1.0.tgz
tar -xzvf cpd-cli-linux-EE-14.1.0.tgz

mv cpd-cli-linux-EE-14.1.0-1189/cpd-cli ~/.local/bin
mv cpd-cli-linux-EE-14.1.0-1189/plugins ~/.local/bin/

rm -rf cpd-cli-plugins cpd-cli-linux-EE-14.1.0.tgz
```

```bash
# Install OpenShift CLI
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
tar -xzvf openshift-client-linux.tar.gz

mv oc kubectl ~/.local/bin/
rm -f openshift-client-linux.tar.gz README.md

# Setup CLI workspace
export CPD_CLI_MANAGE_WORKSPACE=~/cpd-cli-workspace
mkdir -p ${CPD_CLI_MANAGE_WORKSPACE}/{auth,bin,certs,logs,work}
```

#### Download / restart the OLM installer container
```bash
cpd-cli manage restart-container
```

### 4. Configure Environment Variables

We provide a template environment variables file [watsonx_vars.sh](watsonx_vars.sh) with all necessary variables for the installation. This includes:
- OpenShift cluster access configuration
- Project namespace definitions
- Storage class specifications
- Component-specific settings

1. Copy the template to your home directory:
```bash
# Copy template from git repository
cp watsonx_vars.sh ~/.watsonx_vars.sh

# Edit the file with your specific values
vi ~/.watsonx_vars.sh
```

For a complete list of variables and their descriptions, refer to the [watsonx_vars.sh](watsonx_vars.sh) template in this repository.

2. Update `.bashrc`:
```bash
# Add to end of .bashrc
echo "source ~/.watsonx_vars.sh" >> ~/.bashrc
```

3. Apply changes:
```bash
source ~/.bashrc
```

4. Test cluster access:
```bash
# OpenShift Access
$OC_LOGIN

# CPD CLI Login test
$CPDM_OC_LOGIN

# Basic Cluster Health
echo "=== Checking Cluster Health ==="
oc get nodes                                                         # Node status
oc get co                                                           # Cluster operators
oc get clusterversion                                               # OpenShift version

# Storage Health
echo "=== Checking Storage ==="
oc get sc                                                           # Storage classes
oc get pv                                                          # Persistent volumes
oc get pvc --all-namespaces                                        # PVCs across cluster

# Operator Health
echo "=== Checking Operators ==="
oc get sub -A                                                       # Subscriptions
oc get csv -A                                                       # Installed operators
oc get operatorgroup -A                                            # Operator groups

# Pod Health
echo "=== Checking Pod Health ==="
oc get pods -A | grep -v "Running\|Completed"                       # Non-healthy pods
oc get pods -A --field-selector status.phase!=Running,status.phase!=Succeeded   # Alternative non-healthy pods
oc get events --sort-by='.lastTimestamp' -A                        # Recent events

# Resource Usage
echo "=== Checking Resource Usage ==="
oc adm top nodes                                                    # Node resource usage
oc get nodes -o custom-columns=NAME:metadata.name,CPU:status.capacity.cpu,MEMORY:status.capacity.memory   # Node capacity

# Security Context
echo "=== Checking Security ==="
oc get scc                                                          # Security Context Constraints
oc get identity                                                     # Authentication providers
oc auth can-i --list                                               # Permission check
```

⚠️ **Note**: Some commands might require elevated privileges. Adjust according to your access level.

### 5. Verify Installation

1. Check CLI versions:
```bash
# Check OpenShift CLI version
oc version

# Check IBM Cloud Pak CLI version
cpd-cli version

# Verify Python version
python3 --version
```

2. Verify workspace setup:
```bash
# Check workspace structure
ls -la ${CPD_CLI_MANAGE_WORKSPACE}

# Verify directory permissions
namespaces=(auth bin certs logs work)
for ns in "${namespaces[@]}"; do
  if [ ! -d "${CPD_CLI_MANAGE_WORKSPACE}/${ns}" ]; then
    echo "Error: ${ns} directory not found"
    exit 1
  fi
done
```

3. Test registry access:
```bash
# Test IBM registry access (podman)
podman login cp.icr.io --username cp --password ${IBM_ENTITLEMENT_KEY}
```
```bash
# Test IBM registry access (docker)
docker login cp.icr.io --username cp --password ${IBM_ENTITLEMENT_KEY}
```
```bash
# Access IBM registry using CPD CLI
cpd-cli manage login-entitled-registry ${IBM_ENTITLEMENT_KEY}
```

## Troubleshooting

### Common Issues

1. **CLI Installation Failures**
   - Verify internet connectivity
   - Check disk space
   - Ensure proper permissions

2. **Registry Access Issues**
   - Verify entitlement key
   - Check network connectivity
   - Confirm registry credentials

3. **Cluster Access Problems**
   - Verify kubeconfig
   - Check cluster status
   - Confirm user permissions

For detailed debugging commands, refer to [appendix-debugging.md](appendix-debugging.md).
