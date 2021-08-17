# vagrant-k8s-example

A simplistic example of a multi-node kubernetes cluster using Vagrant+VirtualBox. This Vagrantfile creates a 3-node Kubernetes cluster for a quick test drive.

* vm00 - Master node (2 cores, 2GB RAM)
* vm01 - Worker node (4 cores, 4GB RAM)
* vm02 - Worker node (4 cores, 4GB RAM)

They all have similar resource limits, so be aware of those requirements. Adjust as necessary in your local copy. For nodes to communicate, a private host-only network is created: 10.10.10.0/24.

Pods and Services CIDR blocks and other values related to the cluster bootstrap can be changed in `files/kubeadm-config.yaml`.

```yaml
networking:
  serviceSubnet: 10.22.0.0/16
  podSubnet: 10.66.0.0/16
```

Any additional parameters not supported by `ClusterConfiguration` or `InitConfiguration` can be directly passed to `kubeadm` by modifying the Vagrant file in the script provided by the `$script_kubeadm_init` variable.

## Changing component versions

Values for the version of each component can be updated at the top of the Vagrantfile.

```Vagrantfile
K8S_VERSION="1.21.3"
DOCKER_VERSION="5:20.10"
CONTAINERD_VERSION="1.4.9"
```

## Basic usage

Basic Vagrant command line arguments should be enough to get started.

Setting up from scratch:

```
vagrant up
```

Stopping the cluster:

```
vagrant halt
```

Tearing down the cluster:

```
vagrant destroy -f

## remove this directory for a complete cleanup
rm -fr .vagrant
```

## Using the cluster

Once the cluster is up and running, you can control it directly from the master node.

```shell
vagrant ssh vm00

## in vm00's shell

vagrant@vm00:~$ kubectl get pods -n kube-system
NAME                           READY   STATUS    RESTARTS   AGE
coredns-558bd4d5db-sbxq8       1/1     Running   0          5m57s
coredns-558bd4d5db-wkb7m       1/1     Running   0          5m57s
etcd-vm00                      1/1     Running   0          6m13s
kube-apiserver-vm00            1/1     Running   0          6m12s
kube-controller-manager-vm00   1/1     Running   0          6m12s
kube-proxy-7h9pb               1/1     Running   0          3m57s
kube-proxy-bkxnv               1/1     Running   0          119s
kube-proxy-frlvt               1/1     Running   0          5m57s
kube-scheduler-vm00            1/1     Running   0          6m12s
```

## Additional tools installed

The latest stable veresion of the following tools are also installed along with the Kubernetes.

* [Git](https://git-scm.com/)
* [Helm 3](https://helm.sh/docs/)
* [K9s](https://k9scli.io/)
* [kubernetes-helper-scripts](https://github.com/juliohm1978/kubernetes-helper-scripts)
