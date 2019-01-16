# -*- mode: ruby -*-
# vi: set ft=ruby :

DEBIAN_FRONTEND="noninteractive"

# Specify a Consul version
CONSUL_VERSION = ENV['CONSUL_VERSION'] || "1.4.0"

# Specify a custom Vagrant box for the demo
DEMO_BOX_NAME = ENV['DEMO_BOX_NAME'] || "centos/7"

# Vagrantfile API/syntax version.
# NB: Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = DEMO_BOX_NAME

  config.vm.provision "shell",
                          path: "scripts/init.sh",
                          env: {'CONSUL_VERSION' => CONSUL_VERSION}

  config.vm.define "consul0" do |n1|
      n1.vm.hostname = "consul0"
      n1.vm.network "private_network", ip: "172.20.20.10"
  end

  config.vm.define "consul1" do |n2|
      n2.vm.hostname = "consul1"
      n2.vm.network "private_network", ip: "172.20.20.11"
  end

  config.vm.define "consul2" do |n2|
      n2.vm.hostname = "consul2"
      n2.vm.network "private_network", ip: "172.20.20.12"
  end
end
