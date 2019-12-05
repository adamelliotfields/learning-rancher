# RKE

## Instructions

The `rke` binary is installed during Vagrant provisioning. RKE clusters are configured using a file,
`cluster.yml`.

The [`cluster.yml`](./cluster.yml) in this directory will bring up a 2-node Kubernetes cluster using
Flannel, but check out [Config Options](https://rancher.com/docs/rke/latest/en/config-options) and
[Example `cluster.yml`s](https://rancher.com/docs/rke/latest/en/example-yamls) for all of the
configuration options.

```bash
vagrant ssh rancher-master -c 'rke up --config=/vagrant/rke/cluster.yml'

mkdir ~/.kube

# The kube_config_cluster.yml will be created once RKE is finished provisioning.
cat rke/kube_config_cluster.yml > ~/.kube/config
```

## ETCD

Every node in your `cluster.yml` can be assigned one or more roles, including the `etcd` role. In
the included `cluster.yml`, the master node is assigned as the only `etcd` node in the cluster, so
RKE will install an `etcd` database there.

RKE also supports an external `etcd` database **over HTTPS only**. Assuming you followed the
instructions in the [`README`](../README.md) in the root of this repository and created TLS
certificates, you can run a dedicated `etcd` container outside of Kubernetes using the included
[`docker-compose.yml`](./docker-compose.yml).

```bash
vagrant ssh rancher-master -c 'docker-compose -f rke/docker-compose.yml up -d'
```

You now need to edit [`cluster-etcd.yml`](./cluster-etcd.yml) and add your certificates:

```yaml
services:
  etcd:
    path: /
    external_urls:
    - https://192.168.0.2:2379
    ca_cert: |-
      -----BEGIN CERTIFICATE-----
      ...
    cert: |-
      -----BEGIN CERTIFICATE-----
      ...
    key: |-
      -----BEGIN RSA PRIVATE KEY-----
      ...
```

Now bring up the cluster:

```
vagrant ssh rancher-master -c 'rke up --config=/vagrant/rke/cluster-etcd.yml'

mkdir ~/.kube

vagrant ssh rancher-master -c 'cat /vagrant/rke/kube_config_cluster-etcd.yml' > ~/.kube/config
```

> When rebooting your VM, `docker-compose` doesn't always restart your containers automatically, so make sure `etcd` is running.

## Networking

RKE installs [`canal`](https://docs.projectcalico.org/latest/getting-started/kubernetes/installation/flannel)
by default. You can optionally choose from [`calico`](https://github.com/projectcalico/calico),
[`flannel`](https://github.com/coreos/flannel), or [`weave`](https://github.com/weaveworks/weave).

I recommend starting with `flannel`. See [Network Plug-in Options](https://rancher.com/docs/rke/latest/en/config-options/add-ons/network-plugins/#network-plug-in-options)
to learn more about each network plugin.

You also have the option of not installing one of RKE's network plugins and using your own solution.
I've included manifests to deploy [`cilium`](https://github.com/cilium/cilium) using the bare
minimum settings.

## Load Balancer

I've added Helm values for [`metallb`](https://github.com/danderson/metallb).

```bash
helm install metallb stable/metallb -n kube-system -f charts/metallb/values.yaml
```

## Ingress

RKE installs [`ingress-nginx`](https://github.com/kubernetes/ingress-nginx) by default.

I've opted to disable this and install NGINX manually using Helm.

```bash
helm install nginx-ingress stable/nginx-ingress -n kube-system -f charts/values.yaml
```

## Storage

I've added manifests to deploy Rancher's [`local-path-provisioner`](https://github.com/rancher/local-path-provisioner)
to the `kube-system` namespace, as well as manifests to deploy Rancher's [`longhorn`](https://github.com/rancher/longhorn)
to the `longhorn-system` namespace.

`local-path-provisioner` uses basically no resources (it comes with K3s by default), but it does
have a weird bug that prevents you from mounting a volume to a subPath (see [#4](https://github.com/rancher/local-path-provisioner/issues/4)).
This won't be an issue when deploying your own manifests, but could be an issue when using Helm
charts.

`longhorn` is heavier because it is distributed replicated block storage, but it's still lighter and
easier to deploy than other alternatives.

```bash
# Deploy local-path-provisioner
kubectl apply -f manifests/local-path-provisioner

# Deploy longhorn
kubectl apply -f manifests/longhorn
```

If you deployed `longhorn`, you can access the UI by port-forwarding to `localhost:8000`.

```bash
kubectl -n longhorn-system port-forward svc/longhorn-frontend 8000:8000
```

## Kubernetes Dashboard

I've added manifests to deploy [`kubernetes-dashboard`](https://github.com/kubernetes/dashboard)
using the `v2` branch.

Make sure you have `metrics-server` running in your cluster (this is the default behavior for RKE
unless you manually disabled it in your `cluster.yml`).

```bash
kubectl -n kube-system apply -f manifests/dashboard
```

You can access the dashboard by port-forwarding to `localhost:9090`.

```bash
kubectl -n kube-system port-forward svc/dashboard 9090:9090
```

## Clean Up

```bash
vagrant ssh rancher-master -c 'rke remove --config=/vagrant/rke/cluster.yml'

vagrant ssh rancher-worker -c 'just -f /vagrant/Justfile clean'
vagrant ssh rancher-master -c 'just -f /vagrant/Justfile clean'
```
