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

## ⚙️ Pipeline Architecture & Workflow (Deep Dive)

This project implements a fully automated **DevSecOps** pipeline. Below is the exact step-by-step process that occurs on every code change.

### 1. Code Quality Assurance (CI)
*   **Trigger**: Fires on every `push` or `pull_request` to the `main` branch.
*   **Environment**: Runs on `ubuntu-latest` with Node.js 18.
*   **Deterministic Install**: Uses `npm ci` instead of `npm install` to ensure the exact dependency versions from `package-lock.json` are used.
*   **Testing**: Executes `npm test` (Jest) to validate application logic. If tests fail, the pipeline stops immediately.

### 2. Security Scanning (Sec)
Before building artifacts, we scan the codebase to prevent vulnerabilities from entering the supply chain.
*   **Filesystem Vulnerability Scan**: Uses **Trivy** to scan the repository files (`package.json`, `package-lock.json`, etc.) for known CVEs.
*   **Policy**: The pipeline is configured to **fail** if `CRITICAL` or `HIGH` severity vulnerabilities are found.

### 3. Artifact Build & Optimization
*   **Multi-Stage Dockerfile**:
    *   **Stage 1 (Builder)**: Installs full dependencies to support the build process.
    *   **Stage 2 (Production)**: Copies only the `dist` or production `node_modules`. Base image is `node:18-alpine` (lightweight/reduced attack surface).
*   **Container Security**:
    *   **Non-Root User**: The application explicitly switches to the `node` user (UID 1000). It does *not* run as root.
    *   **PID 1 Handling**: Uses `dumb-init` to correctly handle kernel signals (SIGTERM/SIGINT) for graceful shutdowns.
*   **Image Scanning**: Once the image is built, **Trivy** scans the final Docker image layers for OS-level vulnerabilities (e.g., outdated Alpine packages).

### 4. GitOps Delivery (CD)
We do not use `kubectl` in the CI pipeline (Push-based). We use **ArgoCD** (Pull-based).
1.  **Image Push**: The verified Docker image is pushed to **GitHub Container Registry (GHCR)**.
2.  **Manifest Update**: The CI pipeline uses `sed` to edit `k8s/deployment.yaml`. It replaces the image tag with the new Docker image SHA (e.g., `ghcr.io/...:sha-12345`).
3.  **Git Commit**: The CI pipeline commits this change and pushes it back to the `main` branch.
4.  **ArgoCD Sync**:
    *   ArgoCD (running inside K8s) polls the Git repository.
    *   It detects the change in `k8s/deployment.yaml`.
    *   It diffs the desired state (Git) vs. live state (Cluster).
    *   It automatically applies the new Deployment, triggering a rolling update in Kubernetes.
