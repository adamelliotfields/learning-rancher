# Learning Rancher

> :horse: Learning Rancher by example(s).

Rancher offers a few different ways to run Kubernetes, and I wanted to try them all.

## Introduction

This repository contains the resources I put together to work with Rancher locally via Vagrant.

On your host, you should have `kubectl`, `helm`, `rancher`, `step`, and `just` installed, as well as
Vagrant and VirtualBox.

```bash
brew install helm just kubernetes-cli rancher-cli step

brew cask install vagrant virtualbox
```

## Vagrant

The Vagrantfile in the root of this repository will provision 2 virtual machines, forward some
ports, and set up a private network.

There is an accompanying `config.yml` file which can be modified so you shouldn't have to touch the
Vagrantfile directly.

## K3s

K3s is a lightweight Kubernetes distribution that doesn't require as many resources as a traditional
installation.

See [`k3s/README.md`](./k3s/README.md) for instructions on running K3s as a `systemd` service.

## RKE

Rancher Kubernetes Engine (RKE) is CLI for creating and maintaining Kubernetes clusters. RKE is
unique in that it deploys all Kubernetes components in Docker containers.

See [`rke/README.md`](./rke/README.md) for instructions on deploying Kubernetes via RKE, including
some additional configuration options.

## Rancher

Rancher's flagship product is a web application for creating and maintaining Kubernetes clusters.
Under the hood, Rancher uses RKE and is itself running on its own K3s cluster.

See [`rancher/README.md`](./rancher/README.md) for instructions on running Rancher locally using a
trusted certificate authority (read the next section first).

## Certificates

Some of the examples in this repository require a root certificate authority and a x.509
certificate.

I'm using [`step`](https://github.com/smallstep/cli) for local PKI (public key infrastructure) and
[`just`](https://github.com/casey/just) for running scripts.

Run the following commands to set up a certificate authority and create your certificate and key.

```bash
# Creates root and intermediate certs as well as encrypted and decrypted (password-less) keys
just init-ca

# Installs the root certificate into your trust store
just install-ca

# Creates an x.509 certificate and key (view the Justfile for SANs)
just create-certificate

# Install the root certificate into your VMs
vagrant ssh rancher-master -c "sudo sh -c 'HOME=/home/vagrant just -f /vagrant/Justfile install-ca'"
vagrant ssh rancher-worker -c "sudo sh -c 'HOME=/home/vagrant just -f /vagrant/Justfile install-ca'"
```

## Which One?

Below are my take-aways from playing around with Rancher, RKE, and K3s. Keep in mind these are just
my opinions; you could use K3s for a big cluster or use kitchen-sink Rancher for a small cluster.

**Rancher**
  - Robust user access control.
  - Ability to provision and manage multiple clusters.
  - Ability to use managed clusters on AWS, Azure, and Google.
  - Ability to isolate workloads into projects.
  - Built-in monitoring, logging, and alerts.
  - Built-in Istio.
  - Built-in CI/CD with Rancher Pipelines.
  - Web-based GUI and optional CLI.

**RKE**
  - You'd prefer to manage your cluster using a single configuration file and CLI.
  - You need to sign all cluster certificates using your own CA.
  - You'd prefer to configure monitoring yourself or use a 3rd-party like Datadog.
  - You'd prefer to deploy Istio yourself or use LinkerD.
  - You only need a single cluster.
  - You don't want to use a managed Kubernetes service, but you still want cloud provider integration (i.e., nodes, storage, load balancers).
  - You don't need the GUI or don't want to manage the Rancher server.

**K3s**
  - You want a simple cluster that doesn't use a lot of resources.
  - You are running Kubernetes on a Raspberry Pi(s).
  - You plan on deploying your containers to a single-node, but still want all the benefits Kubernetes offers that you can't get from Docker alone.
