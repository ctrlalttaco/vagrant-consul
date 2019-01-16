# Vagrant Consul

## Synopsis

Build a three-node Consul cluster using HashiCorp Vagrant.

## Configuration

Consul Version : `1.4.0`

TLS Enabled : `true`

Datacenter Name: `demo`

Operating System: `CentOS 7`

### Nodes

consul0 - `172.20.20.10`

consul1 - `172.20.20.11`

consul2 - `172.20.20.12`

## Usage

``` bash
vagrant up
```

### ACL Policies

Follow the [Consul ACL Guide](https://learn.hashicorp.com/consul/advanced/day-1-operations/acl-guide) to bootstrap and configure the agent token.

Example Policy:

``` json
node "consul0" {
    policy = "write"
}

node "consul1" {
    policy = "write"
}

node "consul2" {
    policy = "write"
}

service_prefix "" {
    policy = "read"
}
```

## References

[Consul Documentation](https://www.consul.io/docs/index.html)

[Consul Guides](https://www.consul.io/docs/guides/index.html)

[Consul API Reference](https://www.consul.io/api/index.html)

[HashiCorp Learn - Consul](https://learn.hashicorp.com/consul)
