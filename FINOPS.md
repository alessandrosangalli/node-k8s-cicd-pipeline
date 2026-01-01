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

## 5. Right Sizing (Auto-scaling)

The node pool is configured with Cluster Autoscaler:
- **Min Nodes:** 0 (Scale to zero supported to avoid idle costs)
- **Max Nodes:** 3 (Cap costs)

This ensures we only pay for the compute we absolutely need.
