terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Obter credenciais do cluster para os provedores K8s e Helm
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  }
}

# Habilitar APIs necessárias no GCP
resource "google_project_service" "resourcemanager" {
  service                    = "cloudresourcemanager.googleapis.com"
  disable_on_destroy         = false
}

resource "google_project_service" "compute" {
  service                    = "compute.googleapis.com"
  disable_on_destroy         = false
  depends_on                 = [google_project_service.resourcemanager]
}

resource "google_project_service" "container" {
  service                    = "container.googleapis.com"
  disable_on_destroy         = false
  depends_on                 = [google_project_service.resourcemanager]
}

# Cluster GKE Autopilot
resource "google_container_cluster" "primary" {
  name     = "node-k8s-cluster"
  location = var.region

  enable_autopilot = true
  
  network    = "default"
  subnetwork = "default"

  deletion_protection = false

  # Garante que as APIs estejam prontas antes de criar o cluster
  depends_on = [
    google_project_service.compute,
    google_project_service.container,
    google_project_service.resourcemanager
  ]
}

# 1. Instalar ArgoCD via Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.7"
  timeout          = 900   # 15 minutos
  wait             = false # Não trava a pipeline esperando todos os pods subirem
  cleanup_on_fail  = true

  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  depends_on = [google_container_cluster.primary]
}

# 2. Instalar Argo Rollouts via Helm
resource "helm_release" "argo_rollouts" {
  name             = "argo-rollouts"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-rollouts"
  namespace        = "argo-rollouts"
  create_namespace = true
  timeout          = 900 # 15 minutos
  wait             = false
  cleanup_on_fail  = true

  set {
    name  = "dashboard.enabled"
    value = "false"
  }

  depends_on = [google_container_cluster.primary]
}

# 4. Instalar Prometheus via Helm (Otimizado)
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  namespace        = "monitoring"
  create_namespace = true
  version          = "25.8.2"
  wait             = false

  # Desativar componentes pesados que não precisamos agora (AlertManager, PushGateway)
  set {
    name  = "alertmanager.enabled"
    value = "false"
  }
  set {
    name  = "pushgateway.enabled"
    value = "false"
  }

  # Configurar persistência leve (ou desativar para economizar se quiser, mas mantemos 8GB)
  set {
    name  = "server.persistentVolume.size"
    value = "4Gi"
  }

  set {
    name  = "server.retention"
    value = "7d"
  }

  set {
    name  = "server.resources.requests.memory"
    value = "512Mi"
  }

  set {
    name  = "server.resources.limits.memory"
    value = "1Gi"
  }

  # Permitir que o Prometheus rode nas instâncias Spot
  depends_on = [google_container_cluster.primary]
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "argocd_server_host" {
  value = "Aguarde alguns minutos e use 'kubectl get svc -n argocd argocd-server' para obter o IP"
}
