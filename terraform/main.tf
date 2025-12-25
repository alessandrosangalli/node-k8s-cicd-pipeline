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

  # CKV_GCP_21: Labels
  resource_labels = {
    environment = "production"
    project     = "node-k8s-app"
  }

  # CKV_GCP_23: Alias IP ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = ""
    services_secondary_range_name = ""
  }

  # CKV_GCP_20: Master Authorized Networks
  # master_authorized_networks_config {} # checkov:skip=CKV_GCP_20:Acesso simplificado para portfólio público

  # CKV_GCP_64, CKV_GCP_25: Private Cluster
  # private_cluster_config {
  #   enable_private_nodes    = true
  #   enable_private_endpoint = false
  #   master_ipv4_cidr_block  = "172.16.0.0/28"
  # } # checkov:skip=CKV_GCP_64:Acesso simplificado para portfólio público
  # checkov:skip=CKV_GCP_25:Acesso simplificado para portfólio público

  # CKV_GCP_12: Network Policy
  network_policy {
    enabled = true
  }

  # CKV_GCP_69: Workload Identity / GKE Metadata Server
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # CKV_GCP_66: Binary Authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # CKV_GCP_13: Client Certificate Authentication
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # CKV_GCP_61: Enable VPC Flow Logs (Isso exigiria uma subrede dedicada, pulando para manter simplicidade)
  # checkov:skip=CKV_GCP_61:Utilizando rede default para redução de custos/complexidade de demo

  depends_on = [
    google_project_service.compute,
    google_project_service.container,
    google_project_service.resourcemanager
  ]
}

# Criar Namespace dedicado para a aplicação (SRE Best Practice)
resource "kubernetes_namespace" "node_app_ns" {
  metadata {
    name = "node-k8s-app"
  }
  depends_on = [google_container_cluster.primary]
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

  values = [
    yamlencode({
      server = {
        global = {
          scrape_interval = "15s"
          scrape_timeout  = "10s"
        }
      }
    })
  ]

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
