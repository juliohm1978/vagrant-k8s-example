K8S_VERSION="1.21.3"
DOCKER_VERSION="5:20.10"
CONTAINERD_VERSION="1.4.9"

# Install k8s base component and prepares the node
$script_install_kube = <<-SCRIPT
apt-get update
apt-get install -y vim htop git make open-iscsi nfs-common jq 

## Disable swap
swapoff -a

## install k8s tools
apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubeadm=#{K8S_VERSION}* kubectl=#{K8S_VERSION}* kubelet=#{K8S_VERSION}*
apt-mark hold kubeadm kubectl kubelet

## install docker
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce=#{DOCKER_VERSION}* docker-ce-cli=#{DOCKER_VERSION}* containerd.io=#{CONTAINERD_VERSION}*
apt-mark hold docker-ce docker-ce-cli containerd.io

## Install helm
curl -fsSL -o /root/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 /root/get_helm.sh
/root/get_helm.sh

## Disable swap
bash -x /vagrant/files/init/disable-swap.sh
SCRIPT

# Install a few tools on the master node
# - k9s
# - kubernetes-helper-scripts
$script_master_tools = <<-SCRIPT
cd /root

curl -sS https://webinstall.dev/k9s | bash
mv ~/.local/opt/k9s-v0.24.15/bin/k9s /usr/local/bin/

git clone https://github.com/juliohm1978/kubernetes-helper-scripts.git
cd kubernetes-helper-scripts
yes | make install
SCRIPT

$script_kubeadm_init = <<-SCRIPT
rm -fr /vagrant/files/node-join.sh
cp /vagrant/files/init/kubeadm-config.yaml /home/vagrant/
echo "kubernetesVersion: #{K8S_VERSION}" >> /home/vagrant/kubeadm-config.yaml
kubeadm init --config /home/vagrant/kubeadm-config.yaml

mkdir -p /home/vagrant/.kube
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config
echo "export KUBECONFIG=~/.kube/config" >> /home/vagrant/.bashrc

## install calico
helm repo add projectcalico https://docs.projectcalico.org/charts
helm repo up
helm upgrade --install calico projectcalico/tigera-operator --version v3.20.0

kubectl wait --for=condition=Ready node/vm00 --timeout=10m

## Create a KUBECONFIG file and display it
bash /vagrant/files/init/create-client-kubeconfig.sh

## Create a join script for worker nodes
kubeadm token create --print-join-command > /vagrant/files/init/node-join.sh
SCRIPT

$script_kubeadm_join = <<-SCRIPT
bash -xe /vagrant/files/init/node-join.sh
SCRIPT

$script_ssh_fix = <<-SCRIPT
chown -R vagrant.vagrant /home/vagrant
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-20.04"
  config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = 4
  end
  
  config.ssh.forward_agent = true
  
  config.vm.provision "shell", inline: $script_install_kube

  # Create master node
  config.vm.define "vm00" do |v|
    # v.vm.disk :disk, size: "110GB", primary: true
    v.vm.network "private_network", ip: "10.10.10.10"
    v.vm.hostname = "vm00"
    # v.vm.provision :hosts, :sync_hosts => true
    v.vm.provision "master_tools", type: "shell", inline: $script_master_tools
    v.vm.provision "kubeadm_init", type: "shell", inline: $script_kubeadm_init
    v.vm.provision "script_ssh_fix", type: "shell", inline: $script_ssh_fix
    config.vm.provider "virtualbox" do |v|
      v.memory = 2048
      v.cpus = 2
    end
  end

  # Create worker nodes
  (1..2).each do |i|
    config.vm.define "vm0#{i}" do |v|
      # v.vm.disk :disk, size: "100GB", primary: true
      v.vm.network "private_network", ip: "10.10.10.1#{i}"
      v.vm.hostname = "vm0#{i}"
      # v.vm.provision :hosts, :sync_hosts => true
      v.vm.provision "kubeadm_join", after: "kubeadm_init", type: "shell", inline: $script_kubeadm_join
      v.vm.provision "script_ssh_fix", type: "shell", inline: $script_ssh_fix
    end
  end

end
