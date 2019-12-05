#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

rancher_version=2.3.2
rke_version=0.3.2
k3s_version=1.0.0
kubectl_version=1.16.2
helm_version=3.0.0
calico_version=3.8.1
weave_version=2.5.2
compose_version=1.25.0
step_version=0.13.3
just_version=0.5.1
jq_version=1.6

echo 'br_netfilter' >> /etc/modules
echo 'overlay' >> /etc/modules
echo 'net.bridge.bridge-nf-call-iptables=1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables=1' >> /etc/sysctl.conf

modprobe br_netfilter
modprobe overlay

sysctl -p > /dev/null

echo 'iptables-persistent iptables-persistent/autosave_v4 boolean true' | debconf-set-selections
echo 'iptables-persistent iptables-persistent/autosave_v6 boolean true' | debconf-set-selections

apt-get update
apt-get dist-upgrade -y
apt-get install -yq --no-install-recommends apt-transport-https debconf-utils gnupg-agent iptables-persistent open-iscsi software-properties-common

apt-key adv --fetch-keys https://download.docker.com/linux/debian/gpg > /dev/null 2>&1

echo 'deb [arch=amd64] https://download.docker.com/linux/debian buster stable' > /etc/apt/sources.list.d/docker-ce.list

wget -qO /usr/local/bin/jq "https://github.com/stedolan/jq/releases/download/jq-${jq_version}/jq-linux64"
chmod +x /usr/local/bin/jq

mkdir /etc/docker

echo '{"iptables":false,"dns":["1.1.1.1","1.0.0.1"],"exec-opts":["native.cgroupdriver=systemd"]}' | jq -M . > /etc/docker/daemon.json

apt-get update
apt-get install -yq docker-ce docker-ce-cli

usermod -aG docker vagrant

cp -f /etc/iptables/rules.{v4~,v4}
cp -f /etc/iptables/rules.{v6~,v6}
service netfilter-persistent reload

echo -e "Downloading rancher v${rancher_version} ..."
wget -qO /tmp/rancher.tar.gz "https://github.com/rancher/cli/releases/download/v${rancher_version}/rancher-linux-amd64-v${rancher_version}.tar.gz"
tar -C /tmp -xzf /tmp/rancher.tar.gz
cp -p "/tmp/rancher-v${rancher_version}/rancher" /usr/local/bin

echo -e "Downloading rke v${rke_version} ..."
wget -qO /usr/local/bin/rke "https://github.com/rancher/rke/releases/download/v${rke_version}/rke_linux-amd64"
chmod +x /usr/local/bin/rke

echo -e "Downloading k3s v${k3s_version} ..."
wget -qO /usr/local/bin/k3s "https://github.com/rancher/k3s/releases/download/v${k3s_version}/k3s"
chmod +x /usr/local/bin/k3s

echo -e "Downloading kubectl v${kubectl_version} ..."
wget -qO /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v${kubectl_version}/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl

echo -e "Downloading helm v${helm_version} ..."
wget -qO /tmp/helm.tar.gz "https://get.helm.sh/helm-v${helm_version}-linux-amd64.tar.gz"
tar -C /tmp -xzf /tmp/helm.tar.gz
cp -p /tmp/linux-amd64/helm /usr/local/bin

echo -e "Downloading calicoctl v${calico_version} ..."
wget -qO /usr/local/bin/calicoctl "https://github.com/projectcalico/calicoctl/releases/download/v${calico_version}/calicoctl-linux-amd64"
chmod +x /usr/local/bin/calicoctl

echo -e "Downloading weave v${weave_version} ..."
wget -qO /usr/local/bin/weave "https://github.com/weaveworks/weave/releases/download/v${weave_version}/weave"
chmod +x /usr/local/bin/weave

echo -e "Downloading docker-compose v${compose_version} ..."
wget -qO /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-Linux-x86_64"
chmod +x /usr/local/bin/docker-compose

echo -e "Downloading step v${step_version} ..."
wget -qO /tmp/step.tar.gz "https://github.com/smallstep/cli/releases/download/v${step_version}/step_${step_version}_linux_amd64.tar.gz"
tar -C /tmp -xzf /tmp/step.tar.gz
cp -p "/tmp/step_${step_version}/bin/step" /usr/local/bin

echo -e "Downloading just v${just_version}"
wget -qO /tmp/just.tar.gz "https://github.com/casey/just/releases/download/v${just_version}/just-v${just_version}-x86_64-unknown-linux-musl.tar.gz"
tar -C /tmp -xzf /tmp/just.tar.gz
cp -p /tmp/just /usr/local/bin/just

# IP is in CIDR notation, so we want to strip the suffix (the / and everything after).
ip_address=$(ip addr show eth1 | grep -w 'inet' | awk '{ sub("/.*", "", $2); print $2 }')
sed -i "/$HOSTNAME/c\\$ip_address\t$HOSTNAME" /etc/hosts

chown -R vagrant:vagrant /tmp

unset DEBIAN_FRONTEND
