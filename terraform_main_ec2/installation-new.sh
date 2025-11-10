#!/bin/bash
set -euo pipefail

echo "Starting initialization script..."

# Update system
echo "Updating system packages..."
sudo yum update -y || { echo "System update failed"; exit 1; }

# Git install
echo "Installing git..."
if ! sudo yum install git -y; then
  echo "Git installation failed"; exit 1;
fi

# Java dependency for Jenkins (Amazon Corretto 17)
echo "Installing Java 17 (Amazon Corretto)..."
if ! sudo dnf install java-17-amazon-corretto -y; then
  echo "Java installation failed"; exit 1;
fi

# Jenkins install
echo "Configuring Jenkins repo and installing Jenkins..."
if ! sudo wget -q -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo; then
  echo "Failed to download Jenkins repo"; exit 1;
fi
if ! sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key; then
  echo "Failed to import Jenkins key"; exit 1;
fi
if ! sudo yum install jenkins -y; then
  echo "Jenkins installation failed"; exit 1;
fi
if ! sudo systemctl enable jenkins; then
  echo "Failed to enable Jenkins service"; exit 1;
fi
if ! sudo systemctl start jenkins; then
  echo "Failed to start Jenkins service"; exit 1;
fi

# kubectl install
echo "Installing kubectl..."
if ! sudo curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl; then
  echo "kubectl download failed"; exit 1;
fi
sudo chmod +x ./kubectl
if ! sudo mv ./kubectl /usr/local/bin; then
  echo "kubectl move failed"; exit 1;
fi

# eksctl install
echo "Installing eksctl..."
if ! sudo curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp; then
  echo "Failed to download eksctl"; exit 1;
fi
if ! sudo mv /tmp/eksctl /usr/local/bin; then
  echo "eksctl move failed"; exit 1;
fi

# Helm install
echo "Installing Helm..."
if ! wget https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz; then
  echo "Helm download failed"; exit 1;
fi
tar -zxvf helm-v3.6.0-linux-amd64.tar.gz
if ! sudo mv linux-amd64/helm /usr/local/bin/helm; then
  echo "Helm move failed"; exit 1;
fi
chmod 755 /usr/local/bin/helm

# Docker install and setup
echo "Installing Docker..."
if ! sudo yum install docker -y; then
  echo "Docker installation failed"; exit 1;
fi
if ! sudo usermod -aG docker ec2-user; then
  echo "Failed to add ec2-user to docker group"; exit 1;
fi
if ! sudo usermod -aG docker jenkins; then
  echo "Failed to add jenkins user to docker group"; exit 1;
fi
newgrp docker
if ! sudo systemctl start docker; then
  echo "Failed to start Docker service"; exit 1;
fi
sudo chmod 666 /var/run/docker.sock

# Trivy install
echo "Installing Trivy..."
if ! sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.48.3/trivy_0.48.3_Linux-64bit.rpm; then
  echo "Trivy installation failed"; exit 1;
fi

# ArgoCD install
echo "Installing ArgoCD..."
if ! kubectl get namespace argocd >/dev/null 2>&1; then
  if ! kubectl create namespace argocd; then
    echo "Failed to create argocd namespace"; exit 1;
  fi
else
  echo "Namespace argocd already exists"
fi
if ! kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml; then
  echo "Failed to apply ArgoCD manifests"; exit 1;
fi
echo "Waiting for ArgoCD server deployment to become ready..."
if ! kubectl rollout status deployment/argocd-server -n argocd --timeout=120s; then
  echo "ArgoCD server deployment not ready"; exit 1;
fi
echo "ArgoCD installed successfully"

# Grafana and Prometheus install via Helm
echo "Installing Grafana and Prometheus..."
if ! helm repo add stable https://charts.helm.sh/stable; then
  echo "Failed to add stable Helm repo"; exit 1;
fi
if ! helm repo add prometheus-community https://prometheus-community.github.io/helm-charts; then
  echo "Failed to add Prometheus Helm repo"; exit 1;
fi
if ! kubectl create namespace prometheus; then
  echo "Namespace prometheus might already exist"
fi
if ! helm install prometheus-stack prometheus-community/kube-prometheus-stack -n prometheus; then
  echo "Failed to install kube-prometheus-stack"; exit 1;
fi

# SonarQube install
echo "Installing SonarQube..."
if ! sudo yum -y install wget nfs-utils; then
  echo "Failed installing dependencies for SonarQube"; exit 1;
fi
if ! sudo wget -O /etc/yum.repos.d/sonar.repo http://downloads.sourceforge.net/project/sonar-pkg/rpm/sonar.repo; then
  echo "Failed to download Sonar repo"; exit 1;
fi
if ! sudo yum -y install sonar; then
  echo "Sonar installation failed"; exit 1;
fi

# Run SonarQube in Docker
if ! docker run -d --name sonar -p 9000:9000 sonarqube:lts-community; then
  echo "SonarQube Docker container start failed"; exit 1;
fi

echo "All installations and setups completed successfully."
