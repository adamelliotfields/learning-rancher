# Rancher

## Instructions

First, make you followed the instructions in the [`README`](../README.md) in the root of this
repository to initialize your CA, install your CA into your trust store, and create your x.509
certificate. Then run `docker-compose`:

```bash
vagrant ssh rancher-master -c 'docker-compose -f /vagrant/rancher/docker-compose.yml up -d'
```

Once Rancher is up and running, visit <https://192.168.0.2:8443> and create your admin password.

To create your cluster, paste the contents of [`cluster.yml`](./cluster.yml) into the Cluster
Options `Edit as YAML` field, then click `Next`. You'll then generate a command to run on each node.

**This is the important part.** You must click `Show advanced options` and fill in the IP address,
internal IP address, and hostname. Otherwise, Rancher will assume your IP address is the default
`10.0.2.15`. You can find the private IP address of each node in [vagrant.yml](./vagrant.yml).

Add `rancher-master` first and make sure `etcd`, `Control Plane`, and `Worker` are checked.

Run `vagrant ssh rancher-master` and paste the command. Return to the GUI and wait for it to finish
before adding your next node.

Repeat the process for each node (except only check `Worker`).

> Adding a node is very CPU-heavy for a few minutes, so add each one individually.

### Create Rancher CLI API Token

Once your cluster is up, hover over your avatar and click `API & Keys`. Then click `Add Key`. You
want to copy the `Bearer Token`.

_Only do this after you have created a cluster._

### Log in to Rancher from CLI

Paste your token (including the `token-` prefix) after the `--token` flag.

```bash
rancher login https://192.168.0.2:8443 --token='token-...'
```

### Generate Kube Config

```bash
mkdir ~/.kube

rancher kubectl config view --raw > ~/.kube/config
```

### Install Longhorn

In your `System` project, click on `Apps` then click `Launch`.

In the catalog, click `Longhorn`. Adjust the replica counts (default is 3, you only need 1), then
click `Launch` at the bottom of your screen.

### Enable Monitoring

In your Cluster view, click `Enable Monitoring to see live metrics`.

Enable persistent storage for Prometheus and Grafana and resize the volumes to `1Gi`. Then click
`Save` at the bottom of your screen.

## Cleanup

```bash
rancher cluster delete default

vagrant ssh rancher-worker -c 'just -f /vagrant/Justfile clean'
vagrant ssh rancher-master -c 'just -f /vagrant/Justfile clean'
```
