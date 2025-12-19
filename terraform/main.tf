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

# Cluster GKE Standard
resource "google_container_cluster" "primary" {
  name     = "node-k8s-cluster"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

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

# Node Pool Econômico (SPOT)
resource "google_container_node_pool" "spot_nodes" {
  name       = "spot-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    spot         = true
    machine_type = "e2-medium"

    labels = {
      role = "general"
    }

    taint {
      key    = "instance_type"
      value  = "spot"
      effect = "NO_SCHEDULE"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# 1. Instalar ArgoCD via Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.7"

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  # Permitir que o ArgoCD rode nas instâncias Spot
  set {
    name  = "global.tolerations[0].key"
    value = "instance_type"
  }
  set {
    name  = "global.tolerations[0].operator"
    value = "Equal"
  }
  set {
    name  = "global.tolerations[0].value"
    value = "spot"
  }
  set {
    name  = "global.tolerations[0].effect"
    value = "NoSchedule"
  }

  # Estado da Arte: Injetando a aplicação via Helm
  values = [
    yamlencode({
      server = {
        additionalApplications = [
          {
            name      = "node-k8s-app"
            namespace = "argocd"
            project   = "default"
            source = {
              repoURL        = "https://github.com/${var.github_repo}.git"
              targetRevision = "HEAD"
              path           = "k8s/overlays/production"
            }
            destination = {
              server    = "https://kubernetes.default.svc"
              namespace = "default"
            }
            syncPolicy = {
              automated = {
                prune    = true
                selfHeal = true
              }
              syncOptions = ["CreateNamespace=true"]
            }
          }
        ]
      }
    })
  ]
  
  depends_on = [google_container_node_pool.spot_nodes]
}

# 2. Instalar Argo Rollouts via Helm
resource "helm_release" "argo_rollouts" {
  name             = "argo-rollouts"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-rollouts"
  namespace        = "argo-rollouts"
  create_namespace = true

  set {
    name  = "dashboard.enabled"
    value = "true"
  }

  # Permitir que o Argo Rollouts rode nas instâncias Spot
  set {
    name  = "controller.tolerations[0].key"
    value = "instance_type"
  }
  set {
    name  = "controller.tolerations[0].operator"
    value = "Equal"
  }
  set {
    name  = "controller.tolerations[0].value"
    value = "spot"
  }
  set {
    name  = "controller.tolerations[0].effect"
    value = "NoSchedule"
  }

  depends_on = [google_container_node_pool.spot_nodes]
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "argocd_server_host" {
  value = "Aguarde alguns minutos e use 'kubectl get svc -n argocd argocd-server' para obter o IP"
}
