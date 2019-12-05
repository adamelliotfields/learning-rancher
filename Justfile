set shell := ['sudo', 'bash', '-c']

# List available commands.
list:
  #!/bin/bash
  set -e
  just -l

# Clean all artificts.
@clean: _weave-reset _clean-rancher _clean-k3s _clean-disk _clean-networks

@_clean-k3s: _stop-k3s-server _stop-k3s-agent _kill-procs

@_clean-rancher: _remove-containers _remove-volumes

@_clean-disk: _unmount-filesystems _remove-folders _remove-files

@_clean-networks: _remove-networks _iptables-reload

@_weave-reset:
  if weave status > /dev/null 2>&1; then \
    echo 'Removing Weave...'; \
    weave reset > /dev/null 2>&1; \
  fi

@_stop-k3s-server:
  if systemctl is-active -q k3s-server.service; then \
    echo 'Stopping K3s server...'; \
    systemctl disable k3s-server.service > /dev/null 2>&1; \
    systemctl stop k3s-server.service; \
  fi

@_stop-k3s-agent:
  if systemctl is-active -q k3s-agent.service; then \
    echo 'Stopping K3s agent...'; \
    systemctl disable k3s-agent.service > /dev/null 2>&1; \
    systemctl stop k3s-agent.service; \
  fi

@_kill-procs:
  procs=$(lsof | grep /var/lib/rancher | awk '{ print $2 }'); \
  if [[ -n $procs ]]; then \
    echo 'Killing processes...' ;\
    for proc in $procs; do \
      kill -9 "$proc"; \
    done \
  fi

@_remove-containers:
  containers=$(docker ps -q); \
  if [[ -n $containers ]]; then \
    echo 'Stopping Docker containers...'; \
    docker stop $containers > /dev/null; \
  fi
  containers=$(docker ps -a -q); \
  if [[ -n $containers ]]; then \
    echo 'Removing Docker containers...'; \
    docker rm $containers > /dev/null; \
    docker network prune -f > /dev/null 2>&1; \
  fi

@_remove-volumes:
  volumes=$(docker volume ls -q); \
  if [[ -n $volumes ]]; then \
    echo 'Removing Docker volumes...'; \
    docker volume prune -f > /dev/null 2>&1; \
  fi

@_unmount-filesystems:
  echo 'Unmounting temporary filesystems...'
  for mnt in $(mount | grep /run/k3s | awk '{ print $3 }'); do \
    umount "$mnt" > /dev/null 2>&1; \
  done
  for mnt in $(mount | grep /var/lib/kubelet | awk '{ print $3 }'); do \
    umount "$mnt" > /dev/null 2>&1; \
  done
  for mnt in $(mount | grep /var/lib/rancher | awk '{ print $3 }'); do \
    umount "$mnt" > /dev/null 2>&1; \
  done

@_remove-folders:
  echo 'Removing folders...'
  for folder in \
  /etc/ceph \
  /etc/cni \
  /etc/kubernetes \
  /etc/rancher \
  /opt/cni \
  /opt/rke \
  /opt/rke-tools \
  /run/calico \
  /run/flannel \
  /run/k3s \
  /run/secrets/kubernetes.io \
  /var/lib/calico \
  /var/lib/cni \
  /var/lib/etcd \
  /var/lib/kubelet \
  /var/lib/rancher \
  /var/lib/weave \
  /var/log/pods; do \
    if [ -d "$folder" ]; then \
      rm -rf "$folder"; \
    fi \
  done

@_remove-files:
  echo 'Removing files...'
  for file in \
  /run/longhorn-iscsi.lock \
  /vagrant/cluster.rkestate \
  /vagrant/cluster-etcd.rkestate \
  /vagrant/kube_config_cluster.yml \
  /vagrant/kube_config_cluster-etcd.yml \
  /home/vagrant/.kube/config \
  /home/vagrant/.rancher/cli2.json; do \
    if [ -f "$file" ]; then \
      rm -f "$file"; \
    fi \
  done

@_remove-networks:
  echo 'Removing network interfaces...'
  for network in $(ip link show | grep 'master cni0' | awk '{ print $2 }'); do \
    network=${network%@*}; \
    ip link delete "$network"; \
  done
  if ip link show cni0 > /dev/null 2>&1; then \
    ip link delete cni0; \
  fi
  if ip link show flannel.1 > /dev/null 2>&1; then \
    ip link delete flannel.1; \
  fi
  if ip link show tunl0 > /dev/null 2>&1; then \
    modprobe -r ipip; \
  fi

@_iptables-reload:
  echo 'Reloading iptables rules...'
  cp -f /etc/iptables/rules.v{4~,4}
  cp -f /etc/iptables/rules.v{6~,6}
  service netfilter-persistent reload > /dev/null 2>&1

# Initialize certificate authority PKI.
init-ca:
  #!/bin/bash
  set -e
  echo 'password' > /tmp/password
  step ca init \
  --pki \
  --name='Step Certificates' \
  --password-file=/tmp/password
  openssl ec \
  -in ~/.step/secrets/intermediate_ca_key \
  -out ~/.step/certs/intermediate_ca.key \
  -passin file:/tmp/password > /dev/null 2>&1
  openssl ec \
  -in ~/.step/secrets/root_ca_key \
  -out ~/.step/certs/root_ca.key \
  -passin file:/tmp/password > /dev/null 2>&1
  rm /tmp/password

# Install root certificate authority to trust store.
install-ca:
  #!/bin/bash
  set -e
  step certificate install ~/.step/certs/root_ca.crt

# Remove root certificate authority from trust store.
uninstall-ca:
  #!/bin/bash
  set -e
  step certificate uninstall ~/.step/certs/root_ca.crt

# Create x.509 certificate for TLS.
create-certificate:
  #!/bin/bash
  set -e
  step certificate create rancher-master ~/.step/certs/rancher-master.crt ~/.step/certs/rancher-master.key \
  --ca="${HOME}/.step/certs/root_ca.crt" \
  --ca-key="${HOME}/.step/certs/root_ca.key" \
  --kty=RSA \
  --san=rancher-master \
  --san=localhost \
  --san=192.168.0.2 \
  --san=127.0.0.1 \
  --not-after=8760h \
  --no-password \
  --insecure \
  --force
