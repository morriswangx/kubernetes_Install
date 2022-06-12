sudo apt update

# installing the apt-transport-https package which enables working with http and https in Ubuntu’s repositories. Also, install curl as it will be necessary for the next steps.
sudo apt install -y apt-transport-https curl

# Then, add the Kubernetes signing key to both nodes by executing the command:
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add

# Next, we add the Kubernetes repository as a package source on both nodes
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> ~/kubernetes.list
sudo mv ~/kubernetes.list /etc/apt/sources.list.d

# update the node
sudo apt update

# we will install Kubernetes. This involves installing the various tools that make up Kubernetes: kubeadm, kubelet, kubectl, and kubernetes-cni. These tools a
# re installed on all nodes.
sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni

# Kubernetes fails to function in a system that is using swap memory. Hence, it must be disabled in the master node and all worker nodes. Execute the followin
# g command to disable swap memory:
sudo swapoff -a

# Letting Iptables See Bridged Traffic
# For the master and worker nodes to correctly see bridged traffic, you should ensure net.bridge.bridge-nf-call-iptables is set to 1 in your config. First, en
sure the br_netfilter module is loaded. You can confirm this by issuing the command:

lsmod | grep br_netfilter
sudo modprobe br_netfilter
sudo sysctl net.bridge.bridge-nf-call-iptables=1

# Changing Docker Cgroup Driver
# By default, Docker installs with “cgroupfs” as the cgroup driver. Kubernetes recommends that Docker should run with “systemd” as the driver. If you skip thi
# s step and try to initialize the kubeadm in the next step, you will get the following warning in your terminal:

# [preflight] Running pre-flight checks
#    [WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://
kubernetes.io/docs/setup/cri/

# On both master and worker nodes, update the cgroupdriver with the following commands:

sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{ "exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts":
{ "max-size": "100m" },
"storage-driver": "overlay2"
}
EOF

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# remove the config.toml file before restarting the containerd runtime
sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd

# Initialize the Kubernetes Master Node
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

