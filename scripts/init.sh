#!/usr/bin/env bash

echo "Installing dependencies ..."
sudo apt-get update
sudo apt-get install -y unzip curl jq dnsutils

echo "Determining Consul version to install ..."
CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
if [ -z "$CONSUL_DEMO_VERSION" ]; then
    CONSUL_DEMO_VERSION=$(curl -s "${CHECKPOINT_URL}"/consul | jq .current_version | tr -d '"')
fi

echo "Fetching Consul version ${CONSUL_DEMO_VERSION} ..."
cd /tmp/
curl -s https://releases.hashicorp.com/consul/${CONSUL_DEMO_VERSION}/consul_${CONSUL_DEMO_VERSION}_linux_amd64.zip -o consul.zip

echo "Installing Consul version ${CONSUL_DEMO_VERSION} ..."
unzip consul.zip
sudo chmod +x consul
sudo chown root:root consul
sudo mv consul /usr/local/bin/consul
sudo cp /vagrant/systemd/consul.service /etc/systemd/system/consul.service
sudo systemctl daemon-reload

echo "Creating Consul service account ..."
sudo useradd -r -d /etc/consul.d -s /bin/false consul

echo "Creating Consul directory structure ..."
sudo mkdir /etc/consul /etc/consul.d
sudo chown root:consul /etc/consul /etc/consul.d
sudo chmod 0750 /etc/consul /etc/consul.d
sudo mkdir /var/lib/consul
sudo chown consul:consul /var/lib/consul
sudo chmod 0750 /var/lib/consul

echo "Copy PKI certificates ..."
sudo cp /vagrant/pki/{client,server,cli}*.pem /etc/consul
sudo cp /vagrant/pki/ca.pem /etc/consul
sudo chown root:consul /etc/consul/*
sudo chmod 0640 /etc/consul/*

echo "Creating Consul config ..."
NETWORK_INTERFACE=$(ls -1 /sys/class/net | grep -v lo | sort -r | head -n 1)
IP_ADDRESS=$(ip address show $NETWORK_INTERFACE | awk '{print $2}' | egrep -o '([0-9]+\.){3}[0-9]+')
HOSTNAME=$(hostname -s)

sudo tee /etc/consul.d/consul.json << EOF
{
    "datacenter": "demo",
    "node_name": "${HOSTNAME}",
    "data_dir": "/var/lib/consul",
    "log_level": "INFO",
    "enable_syslog": true,
    "ui": true,
    "server": true,
    "advertise_addr": "${IP_ADDRESS}",
    "bootstrap_expect": 3,
    "retry_join": ["172.20.20.10", "172.20.20.11", "172.20.20.12"],
    "encrypt": "3Zp3zLg7eQNA9p+asQhU8A==",
    "encrypt_verify_incoming": true,
    "encrypt_verify_outgoing": true,
    "addresses": {
        "https": "${IP_ADDRESS}"
    },
    "key_file": "/etc/consul/server-key.pem",
    "cert_file": "/etc/consul/server.pem",
    "ca_file": "/etc/consul/ca.pem",
    "verify_outgoing": true,
    "verify_server_hostname": true,
    "acl": {
        "enabled": true,
        "down_policy": "extend-cache"
    }
}
EOF

sudo chown root:consul /etc/consul.d/consul.json
sudo chmod 0640 /etc/consul.d/consul.json

sudo systemctl enable consul
sudo systemctl restart consul