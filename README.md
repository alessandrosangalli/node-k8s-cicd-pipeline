# Gold Standard Node.js Kubernetes Pipeline

This project demonstrates a production-grade **DevSecOps** pipeline for a Node.js microservice. It uses the industry's most sought-after (free) tools to create a robust, secure, and scalable deployment architecture.

## 🏆 Project Highlights (Why is this "Gold Standard"?)

*   **GitOps Workflow**: Uses **ArgoCD** for continuous deployment. The registry is the source of truth.
*   **Security First**:
    *   **Trivy**: Automated vulnerability scanning for both filesystem and container images in the CI pipeline.
    *   **Non-Root User**: The container runs as a non-privileged `node` user.
    *   **Helmet**: HTTP header security.
*   **Observability**:
    *   **Prometheus Metrics**: Built-in `/metrics` endpoint exposing runtime metrics (CPU, Memory, Request counts).
    *   **Structured Logging**: Uses `Winston` for JSON-formatted logs, ready for ELK/Datadog ingestion.
    *   **Health Probes**: Implements liveness and readiness probes for Kubernetes self-healing.
*   **Performance & Scalability**:
    *   **Horizontal Pod Autoscaler (HPA)**: Automatically scales pods based on CPU utilization.
    *   **Multi-Stage Builds**: Dockerfile is optimized for cache layering and small image size.
*   **Testing**: Includes Unit/Integration tests with **Jest** and **Supertest**.

## 🛠 Tech Stack

*   **Application**: Node.js, Express, Winston, Prom-client
*   **CI**: GitHub Actions
*   **CD**: ArgoCD
*   **Container**: Docker
*   **Orchestration**: Kubernetes (compatible with Minikube, Kind, EKS, GKE)
*   **Scanner**: AquaSecurity Trivy

## 🚀 Getting Started

### Prerequisites

*   Node.js & npm
*   Docker
*   Kubernetes Cluster (Minikube or Kind recommended for local)
*   kubectl

### Local Development

1.  **Install Dependencies**
    ```bash
    npm install
    ```

2.  **Run Locally** (with hot-reload)
    ```bash
    npm run dev
    ```

3.  **Run Tests**
    ```bash
    npm test
    ```

4.  **View Metrics**
    Visit `http://localhost:3000/metrics`.

### 🐳 Docker Build

```bash
docker build -t node-k8s-service .
docker run -p 3000:3000 node-k8s-service
```

## ☸️ Kubernetes Deployment

### 1. Manual Deployment (For Testing)

```bash
# Apply all manifests
kubectl apply -f k8s/
```

### 2. GitOps Deployment (ArgoCD) - *Recommended*

1.  Install ArgoCD in your cluster:
    ```bash
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ```

2.  Apply the Application Manifest:
    *(Ensure you have pushed this code to your own GitHub repository first and updated `argocd/application.yaml` with your repo URL)*
    ```bash
    kubectl apply -f argocd/application.yaml
    ```

3.  Access ArgoCD UI and watch the magic happen.

## 🔄 CI/CD Pipeline Flow

1.  **Code Push**: Developer pushes to `main`.
2.  **CI (GitHub Actions)**:
    *   Runs `npm install` & `npm test`.
    *   Runs **Trivy** to scan code for vulnerabilities.
    *   Builds Docker Image.
    *   Runs **Trivy** to scan the *Image* for OS-level vulnerabilities.
    *   Pushes image to GitHub Container Registry (GHCR).
    *   *GitOps Hook*: Updates `k8s/deployment.yaml` with the new image tag and commits it back to the repo.
3.  **CD (ArgoCD)**:
    *   Detects the change in the git repository.
    *   Syncs the cluster state to match the new manifest.
