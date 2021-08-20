#!/bin/bash
########################################
## ADJUST ACCORDING TO YOUR REQUIREMENTS
########################################
CLUSTERNAME=vagrant
NS=kube-system
USERNAME=vagrant
CLUSTERROLE=cluster-admin
KUBECONFIG_NEWFILE=/home/vagrant/kube.config
rm -fr $KUBECONFIG_NEWFILE

########################################
## Create /tmp/kube.config
########################################
kubectl create serviceaccount -n $NS $USERNAME
kubectl create clusterrolebinding $USERNAME --clusterrole=$CLUSTERROLE --serviceaccount=$NS:$USERNAME
kubectl get serviceaccount -n $NS $USERNAME -ojsonpath='{.secrets[0].name}' | xargs kubectl get secret -n $NS -o go-template='{{index .data "ca.crt"}}' | base64 -d > /tmp/ca.crt
TOKEN=$(kubectl get serviceaccount -n $NS $USERNAME -ojsonpath='{.secrets[0].name}' | xargs kubectl get secret -n $NS -o jsonpath='{.data.token}' | base64 -d)
APISERVER=$(TERM=dumb kubectl cluster-info | grep --color=never -E 'Kubernetes master|Kubernetes control plane' | awk '/http/ {print $NF}')
kubectl --kubeconfig=$KUBECONFIG_NEWFILE config set-cluster $CLUSTERNAME --server=$APISERVER --certificate-authority=/tmp/ca.crt --embed-certs=true
kubectl --kubeconfig=$KUBECONFIG_NEWFILE config set-credentials $USERNAME --token=$TOKEN
kubectl --kubeconfig=$KUBECONFIG_NEWFILE config set-context $CLUSTERNAME --cluster=$CLUSTERNAME --user=$USERNAME --namespace=""
kubectl --kubeconfig=$KUBECONFIG_NEWFILE config use-context $CLUSTERNAME

########################################
## Testing $KUBECONFIG_NEWFILE
########################################
kubectl --kubeconfig=$KUBECONFIG_NEWFILE get nodes

echo "#################################################"
echo "# TO USE FROM YOUR HOME: ~/.kube/config.vagrant"
echo "#################################################"
cat ~/tmp/kube.config
echo "#################################################"
