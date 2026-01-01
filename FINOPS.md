# FinOps Guidelines

This document outlines the FinOps practices implemented in this project to ensure cost visibility, optimization, and accountability for the Kubernetes infrastructure on Google Cloud.

## 1. Resource Labeling Strategy

We use a consistent labeling strategy across Google Cloud resources and Kubernetes objects to ensure costs can be allocated to the correct teams and cost centers.

### Standard Labels

| Label Key     | Description                                      | Example Value |
|Data Type      | Tag / Metadata                                   | String        |
|---------------|--------------------------------------------------|---------------|
| `environment` | Deployment environment (dev, staging, prod)      | `production`  |
| `project`     | Name of the project or application               | `node-k8s-app`|
| `team`        | Team responsible for the resource                | `devops`      |
| `cost-center` | Accounting code for chargeback                   | `1001`        |

These labels are applied to:
- GKE Cluster (GCP Labels)
- Node Pools (Kubernetes Labels)

## 2. GKE Cost Allocation

**Status:** Enabled

We have enabled GKE Cost Allocation in the cluster settings. This feature allows Google Cloud Billing to categorize costs by:
- Kubernetes Namespaces
- Kubernetes Labels

This enables granular views of how much each microservice or team is consuming within the shared cluster.

## 3. Cost Optimization (Spot Instances)

**Status:** Implemented

To reduce compute costs, we utilize **Spot VMs** (Preemptible) for our worker nodes.
- **Node Pool:** `spot-node-pool`
- **Savings:** Typically 60-90% discount compared to standard instances.
- **Trade-off:** Nodes can be reclaimed by Google at any time. Our application is stateless and resilient to node restarts.

## 4. Budgets and Alerts (Recommendation)

It is highly recommended to configure a Budget in the Google Cloud Billing Console:
1. Go to **Billing** > **Budgets & alerts**.
2. Create a budget for the project.
3. Set a monthly threshold (e.g., $50).
4. Configure alerts at 50%, 90%, and 100% of the budget.

## 5. Showback & Unit Economics (Value-based Costing)

**Status:** Implemented via Grafana

We move beyond simple "cost tracking" to "value tracking".
- **Dashboard:** `FinOps: Unit Economics & Efficiency` (Grafana)
- **Key Metric:** `Cost per Transaction` (Custo por Transação).
- **Goal:** Understand if cost increases are due to inefficiency (bad) or business growth (good).

## 6. Predictive Autoscaling (KEDA)

**Status:** Implemented

Instead of reactive scaling (waiting for CPU to spike), we use **KEDA** to scale proactively:
- **Traffic-based:** Scales *before* CPU saturation based on RPS (Requests Per Second).
- **Time-based (Cron):** Pre-scales the cluster during business hours (08:00 - 20:00) to handle predictable load.
- **Node Savings:** The Cluster Autoscaler works in tandem, provisioning nodes only when KEDA demands more pods.
