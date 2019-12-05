# K3s

## Instructions

Vagrant up.

```bash
vagrant up
```

Start the K3s server.

```bash
vagrant ssh rancher-master

sudo systemctl enable k3s-server.service
sudo systemctl start k3s-server.service

# Tail the systemd logs
sudo journalctl -f -u k3s-server

exit
```

Once the server is finished starting, you can join the agent to the cluster.

```bash
vagrant ssh rancher-worker

sudo systemctl enable k3s-agent.service
sudo systemctl start k3s-agent.service

exit
```

Now you just need the `KUBECONFIG` on your host.

```bash
# If you don't have kubectl yet
brew install kubernetes-cli

mkdir ~/.kube

# The --write-kubeconfig flag in k3s-server automatically writes the KUBECONFIG for us inside rancher-master
vagrant ssh rancher-master -c 'cat /home/vagrant/.kube/config' > ~/.kube/config

# Make sure it works
kubectl cluster-info
kubectl get nodes
```

## Clean Up

The `clean` script will stop all `systemd` services, kill all `containerd` processes, remove all
filesystem mounts, folders, and network interfaces that were created by K3s, drop and reset your
`iptables`.

Run this on each node using `vagrant ssh`.

```bash
vagrant ssh rancher-master -c 'just -f /vagrant/Justfile clean'
vagrant ssh rancher-worker -c 'just -f /vagrant/Justfile clean'
```

## Docker

I prefer to run K3s as a `systemd` service on Linux, but if you want to run K3s in Docker on your
Mac, check out [`k3d`](https://github.com/rancher/k3d).
