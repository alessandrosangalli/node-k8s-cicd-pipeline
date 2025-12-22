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
  timeout          = 900   # 15 minutos
  wait             = false # Não trava a pipeline esperando todos os pods subirem
  cleanup_on_fail  = true

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

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

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]
  
  depends_on = [google_container_node_pool.spot_nodes]
}

# 3. Bootstrapping: Criar a aplicação no ArgoCD via Manifesto
resource "kubernetes_manifest" "argocd_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "node-k8s-app"
      namespace = "argocd"
    }
    spec = {
      project = "default"
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
      # Impedir que o ArgoCD atropele os passos do Canary do Argo Rollouts
      ignoreDifferences = [
        {
          group = "argoproj.io"
          kind  = "Rollout"
          jsonPointers = [
            "/spec/replicas", 
            "/status"
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.argocd]
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
    value = "true"
  }

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
    value = "8Gi"
  }

  # Permitir que o Prometheus rode nas instâncias Spot
  set {
    name  = "server.tolerations[0].key"
    value = "instance_type"
  }
  set {
    name  = "server.tolerations[0].operator"
    value = "Equal"
  }
  set {
    name  = "server.tolerations[0].value"
    value = "spot"
  }
  set {
    name  = "server.tolerations[0].effect"
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
