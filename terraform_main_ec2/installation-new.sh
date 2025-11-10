#!/bin/bash
set -euo pipefail

echo "Starting initialization script..."

# Update system
echo "Updating system packages..."
sudo yum update -y || { echo "System update failed"; exit 1; }

# Git install
echo "Installing git..."
sudo yum install git -y || { echo "Git installation failed"; exit 1; }

# Java dependency for Jenkins (Amazon Corretto 17)
echo "Installing Java 17 (Amazon Corretto)..."
sudo dnf install java-17-amazon-corretto -y || { echo "Java installation failed"; exit 1; }

# Jenkins install
echo "Configuring Jenkins repo and installing Jenkins..."
sudo wget -q -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo || { echo "Failed to download Jenkins repo"; exit 1; }
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key || { echo "Failed to import Jenkins key"; exit 1; }
sudo yum install jenkins -y || { echo "Jenkins installation failed"; exit 1; }
sudo systemctl enable jenkins || { echo "Failed to enable Jenkins service"; exit 1; }
sudo systemctl start jenkins || { echo "Failed to start Jenkins service"; exit 1; }

# Terraform install
echo "Installing Terraform..."
sudo yum install -y yum-utils || { echo "yum-utils install failed"; exit 1; }
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo || { echo "Failed to add HashiCorp repo"; exit 1; }
sudo yum -y install terraform || { echo "Terraform installation failed"; exit 1; }

# Maven install
echo "Installing Maven..."
sudo yum install maven -y || { echo "Maven installation failed"; exit 1; }

# kubectl install
echo "Installing kubectl..."
sudo curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl || { echo "kubectl download failed"; exit 1; }
sudo chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin || { echo "kubectl move failed"; exit 1; }

# eksctl install
echo "Installing eksctl..."
sudo curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp || { echo "Failed to download eksctl"; exit 1; }
sudo mv /tmp/eksctl /usr/local/bin || { echo "eksctl move failed"; exit 1; }

# Helm install
echo "Installing Helm..."
wget https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz || { echo "Helm download failed"; exit 1; }
tar -zxvf helm-v3.6.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm || { echo "Helm move failed"; exit 1; }
chmod 755 /usr/local/bin/helm

# Docker install and setup
echo "Installing Docker..."
sudo yum install docker -y || { echo "Docker installation failed"; exit 1; }
sudo usermod -aG docker ec2-user || { echo "Failed to add ec2-user to docker group"; exit 1; }
sudo usermod -aG docker jenkins || { echo "Failed to add jenkins user to docker group"; exit 1; }
newgrp docker
sudo systemctl start docker || { echo "Failed to start Docker service"; exit 1; }
sudo chmod 666 /var/run/docker.sock

# Trivy install
echo "Installing Trivy..."
sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.48.3/trivy_0.48.3_Linux-64bit.rpm || { echo "Trivy installation failed"; exit 1; }

# ArgoCD install
echo "Installing ArgoCD..."

if ! kubectl get namespace argocd >/dev/null 2>&1; then
  kubectl create namespace argocd || { echo "Failed to create argocd namespace"; exit 1; }
else
  echo "Namespace argocd already exists"
fi

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || { echo "Failed to apply ArgoCD manifests"; exit 1; }

echo "Waiting for ArgoCD server deployment to become ready..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=120s || { echo "ArgoCD server deployment not ready"; exit 1; }

echo "ArgoCD installed successfully"

# Grafana and Prometheus install via Helm
echo "Installing Grafana and Prometheus..."

helm repo add stable https://charts.helm.sh/stable || { echo "Failed to add stable Helm repo"; exit 1; }
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || { echo "Failed to add Prometheus Helm repo"; exit 1; }
kubectl create namespace prometheus || echo "namespace prometheus might already exist"
helm install prometheus-stack prometheus-community/kube-prometheus-stack -n prometheus || { echo "Failed to install kube-prometheus-stack"; exit 1; }

# SonarQube install
echo "Installing SonarQube..."

sudo yum -y install wget nfs-utils || { echo "Failed installing dependencies for SonarQube"; exit 1; }
sudo wget -O /etc/yum.repos.d/sonar.repo http://downloads.sourceforge.net/project/sonar-pkg/rpm/sonar.repo || { echo "Failed to download Sonar repo"; exit 1; }
sudo yum -y install sonar || { echo "Sonar installation failed"; exit 1; }

# Run SonarQube in Docker
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community || { echo "SonarQube Docker container start failed"; exit 1; }

echo "All installations and setups completed successfully."
