#!/usr/bin/env bash

export PATH=$PATH:/usr/local/bin

echo "Installing dependencies ..."
yum -y makecache
yum -y install unzip curl

echo "Installing Consul version ${CONSUL_VERSION} ..."
curl -s -O https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
curl -s -O https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS
curl -s -O https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig

unzip consul_${CONSUL_VERSION}_linux_amd64.zip
chown root:root consul
chmod 0755 consul
mv consul /usr/local/bin

consul -autocomplete-install
complete -C /usr/local/bin/consul consul

echo "Creating Consul service account ..."
useradd -r -d /etc/consul.d -s /bin/false consul

echo "Creating Consul directory structure ..."
mkdir /etc/consul{,.d}
chown root:consul /etc/consul{,.d}
chmod 0750 /etc/consul{,.d}

mkdir /var/lib/consul
chown consul:consul /var/lib/consul
chmod 0750 /var/lib/consul

echo "Copy PKI certificates ..."
cp /vagrant/pki/server{,-key}.pem /etc/consul
cp /vagrant/pki/ca.pem /etc/consul
chown root:consul /etc/consul/*
chmod 0640 /etc/consul/*

echo "Creating Consul config ..."
NETWORK_INTERFACE=$(ls -1 /sys/class/net | grep -v lo | sort -r | head -n 1)
IP_ADDRESS=$(ip address show $NETWORK_INTERFACE | awk '{print $2}' | egrep -o '([0-9]+\.){3}[0-9]+')
HOSTNAME=$(hostname -s)

cat > /etc/consul.d/consul.json << EOF
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
        "default_policy": "deny",
        "down_policy": "extend-cache"
    }
}
EOF

chown root:consul /etc/consul.d/consul.json
chmod 0640 /etc/consul.d/consul.json

cat > /etc/systemd/system/consul.service << EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.json

[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable consul
systemctl restart consul