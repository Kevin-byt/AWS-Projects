#!/bin/bash

# Vault Initialization Script
VAULT_VERSION="${vault_version}"

# Update system
apt-get update
apt-get install -y curl unzip

# Install Vault
curl -O https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip
unzip vault_${vault_version}_linux_amd64.zip
mv vault /usr/local/bin/
chmod +x /usr/local/bin/vault

# Create Vault user and directories
useradd --system --home /etc/vault.d --shell /bin/false vault
mkdir -p /etc/vault.d
mkdir -p /var/lib/vault
chown -R vault:vault /etc/vault.d /var/lib/vault

# Create Vault configuration
cat << EOF > /etc/vault.d/vault.hcl
storage "file" {
  path = "/var/lib/vault"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

api_addr = "http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):8200"
ui = true
EOF

chown vault:vault /etc/vault.d/vault.hcl

# Create systemd service
cat << EOF > /etc/systemd/system/vault.service
[Unit]
Description=Vault
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitBurst=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Start Vault service
systemctl enable vault
systemctl start vault

# Wait for Vault to start and verify it's responding
echo "Waiting for Vault to start..."
for i in {1..30}; do
    if curl -s -f http://127.0.0.1:8200/v1/sys/health > /dev/null 2>&1; then
        echo "Vault is responding after $i attempts"
        break
    fi
    echo "Attempt $i: Vault not yet responding, waiting..."
    sleep 10
done

# Verify Vault is actually running
if ! curl -s -f http://127.0.0.1:8200/v1/sys/health > /dev/null 2>&1; then
    echo "ERROR: Vault failed to start properly" | tee -a /var/log/vault-init.log
    systemctl status vault | tee -a /var/log/vault-init.log
    exit 1
fi

# Install jq and AWS CLI (for uploading token to SSM)
apt-get install -y jq awscli

# Initialize Vault (NOT for production — demo initialization)
export VAULT_ADDR='http://127.0.0.1:8200'
echo "Initializing Vault..." | tee -a /var/log/vault-init.log

# Check if Vault is already initialized
if vault status 2>/dev/null | grep -q "Initialized.*true"; then
    echo "Vault is already initialized" | tee -a /var/log/vault-init.log
    exit 0
fi

# Initialize Vault
if ! vault operator init -key-shares=1 -key-threshold=1 -format=json | tee /var/log/vault-init.log > /tmp/vault-init.json; then
    echo "ERROR: Failed to initialize Vault" | tee -a /var/log/vault-init.log
    exit 1
fi

# Extract unseal key and root token
UNSEAL_KEY=$(jq -r '.unseal_keys_b64[0]' /tmp/vault-init.json)
ROOT_TOKEN=$(jq -r '.root_token' /tmp/vault-init.json)

if [ -z "$UNSEAL_KEY" ] || [ -z "$ROOT_TOKEN" ] || [ "$UNSEAL_KEY" = "null" ] || [ "$ROOT_TOKEN" = "null" ]; then
    echo "ERROR: Failed to extract unseal key or root token" | tee -a /var/log/vault-init.log
    exit 1
fi

# Unseal Vault
echo "Unsealing Vault..." | tee -a /var/log/vault-init.log
if ! vault operator unseal $UNSEAL_KEY; then
    echo "ERROR: Failed to unseal Vault" | tee -a /var/log/vault-init.log
    exit 1
fi

# Verify Vault is unsealed and ready
for i in {1..10}; do
    if vault status 2>/dev/null | grep -q "Sealed.*false"; then
        echo "Vault is unsealed and ready" | tee -a /var/log/vault-init.log
        break
    fi
    echo "Waiting for Vault to be unsealed... attempt $i" | tee -a /var/log/vault-init.log
    sleep 5
done

# Store root token into SSM Parameter Store as SecureString
SSM_PARAM_NAME="/vault/root_token"
echo "Storing root token in SSM Parameter Store..." | tee -a /var/log/vault-init.log
if aws ssm put-parameter --name "$SSM_PARAM_NAME" --value "$ROOT_TOKEN" --type "SecureString" --overwrite --region "${aws_region}"; then
    echo "SUCCESS: Vault installation completed and root token stored in SSM at $SSM_PARAM_NAME" | tee -a /var/log/vault-init.log
else
    echo "ERROR: Failed to store root token in SSM" | tee -a /var/log/vault-init.log
    exit 1
fi

# Clean up sensitive files
rm -f /tmp/vault-init.json
echo "Vault initialization completed successfully" | tee -a /var/log/vault-init.log
