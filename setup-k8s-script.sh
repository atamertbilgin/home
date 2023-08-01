#!/bin/bash

# Sleep for 20 seconds
sleep 20

# Update the system and install necessary packages
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# Sleep for 180 seconds (3 minutes)
sleep 180


sudo usermod -aG docker $USER
sudo systemctl restart docker
kubectl config set-cluster abilgin --server=localhost
kubectl config set-context abilgin --cluster=abilgin --user=kubectl
kubectl config use-context abilgin
sudo systemctl start kube-apiserver
# Login to AWS ECR
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 611289949201.dkr.ecr.us-east-1.amazonaws.com

# Create and use Docker registry secret in Kubernetes
kubectl create secret docker-registry regcred \
    --docker-server=611289949201.dkr.ecr.us-east-1.amazonaws.com \
    --docker-username=AWS \
    --docker-password=$(aws ecr get-login-password --region us-east-1) \
    --docker-email=atamertbilgin@gmail.com

# Clone Git repository, build and push Docker image to ECR
docker build -t my-docker-image .
docker tag my-docker-image:latest 611289949201.dkr.ecr.us-east-1.amazonaws.com/abilgin-portfolio-image:latest
docker push 611289949201.dkr.ecr.us-east-1.amazonaws.com/abilgin-portfolio-image:latest

kubectl config set-cluster abilgin --server=localhost
