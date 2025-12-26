# Pipeline Kubernetes Estado da Arte [![Semantic Release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

Este repositório contém uma implementação de referência para engenharia de software moderna, demonstrando uma pipeline **DevSecOps** completa para um microserviço Node.js. O projeto foi desenhado focando nos pilares de **Confiabilidade (SRE)**, **Segurança (Security-First)** e **Entrega Contínua (GitOps)**.

## 🌟 Destaques da Arquitetura

### 1. Entrega Progressiva & GitOps
Utilizamos uma abordagem GitOps pura onde o Git é a única fonte de verdade.
*   **ArgoCD**: Sincronização automática do estado do cluster com o repositório.
*   **Argo Rollouts (Canary Deployments)**: Deploys graduais que reduzem o risco de impacto negativo. O tráfego é migrado progressivamente (20% -> 50% -> 100%) com análise automática de taxas de erro.
*   **Kustomize**: Gerenciamento de configuração hierárquico (Base/Overlays) para múltiplos ambientes (Dev/Prod) sem duplicação.

### 2. Automação de Release (Novo!)
A pipeline implementa **Semantic Versioning** totalmente automatizado:
*   **Tags Semânticas**: Gera tags (v1.0.0, v1.1.0) baseadas na análise dos commits (Conventional Commits).
*   **Changelog Automático**: Gera notas de release detalhadas a cada versão.
*   **Release-First Workflow**: O build e deploy Docker só ocorrem após uma versão ser oficialmente "tageada", garantindo rastreabilidade total do que está rodando em produção.

### 3. Observabilidade SRE 2.0
Dashboards, métricas e alertas tratados como código (Observability as Code).
*   **SLOs as Code (Sloth)**: Definição científica de confiabilidade com **Service Level Objectives** de Disponibilidade (99.9%) e Latência (95% < 500ms).
*   **Distributed Tracing (Tempo)**: Rastreamento completo de requisições ponta-a-ponta integrado ao Grafana.
*   **Grafana as Code**: Dashboards e Data Sources provisionados automaticamente via ConfigMaps.
*   **Golden Signals**: Monitoramento nativo de Latência, Tráfego, Erros e Saturação via OpenTelemetry.

### 4. Segurança em Profundidade (DevSecOps)
*   **Zero Trust Networking**: Network Policies estritas (Calico) que bloqueiam por padrão todo o tráfego lateral no cluster.
*   **Node Hardening**: Nodes utilizam **Secure Boot** (Shielded GKE Nodes) e integridade verificada de bootloader. A gestão é automatizada com Auto-Repair e Auto-Upgrade.
*   **Imutabilidade & Integridade**: Imagens fixadas via **SHA256 Digest** e sistema de arquivos do container em modo **Read-Only**.
*   **IaC Security Scanner**: Uso de **Checkov** para análise estática em manifestos Kubernetes e Terraform (0 falhas críticas).
*   **Supply Chain Security**: Escaneamento de vulnerabilidades com **Trivy** (CVE scan) automatizado na pipeline.
*   **Rootless Execution**: Containers rodam com usuário não-root (UID 10001) e capabilities de kernel removidas.

### 5. FinOps & Otimização de Custos (Novo!)
Arquitetura desenhada para eficiência econômica máxima sem sacrificar a robustez:
*   **Spot Fleet Strategy**: O ambiente de produção roda, em **Spot Instances (Preemptible)**, reduzindo os custos de computação em até **90%** em comparação com instâncias sob demanda.
*   **Resiliência a Falhas**: A aplicação foi projetada para sobreviver à natureza volátil das instâncias Spot (Chaos Engineering nativo).
*   **Autoscaling Inteligente**: O cluster escala seus nós de 0 a 3 automaticamente, custando **zero** quando ocioso.
*   **Log Retention Policy**: Retenção de métricas (Prometheus) e logs otimizada para reduzir custos de armazenamento persistente.

## 🛠 Stack Tecnológica

| Componente | Tecnologia | Função |
| :--- | :--- | :--- |
| **Runtime** | Node.js 22 (LTS) | Execução do serviço de alta performance |
| **Observabilidade 2.0** | OpenTelemetry, Tempo & Sloth | Tracing distribuído e SLOs as Code |
| **Orquestração** | Kubernetes & GKE | Gerenciamento de containers |
| **GitOps** | ArgoCD & Kustomize | Continuous Delivery & Configuration |
| **Progressive Delivery** | Argo Rollouts | Canary Deployments |
| **Observabilidade** | Prometheus & Grafana | Monitoramento e Dashboards |
| **Segurança** | Checkov, Trivy & NetPol | DevSecOps & Zero Trust |
| **Infraestrutura** | Terraform & GKE (Spot) | IaC & Cost Optimization |
| **Release** | Semantic Release | Versionamento Automático |

## 🚀 Como Executar

### Pré-requisitos
*   Node.js 20+
*   Docker
*   Kubernetes (Minikube/Kind/GKE)
*   **GitOps Ready**: O Sloth CRD e todas as dependências são gerenciados automaticamente via Kustomize.
*   [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (Para deploy em GKE)
*   [Terraform](https://developer.hashicorp.com/terraform/install) (Para IaC)

### Provisionando Infraestrutura (Terraform)
Este projeto inclui uma configuração Terraform completa para subir um cluster GKE otimizado (Spot/Standard).

```bash
cd terraform

# Autenticar no GCP
gcloud auth application-default login

# Inicializar e Aplicar
terraform init
terraform apply
```

### Desenvolvimento Local
```bash
# Instalar dependências
npm install

# Rodar em modo de desenvolvimento
npm run dev

# Rodar testes
npm test
```

### Simulando um Release
Para acionar a pipeline de release, utilize mensagens de commit seguindo o padrão [Conventional Commits](https://www.conventionalcommits.org/):

*   `fix: ...` -> Gera versão **Patch** (v1.0.1)
*   `feat: ...` -> Gera versão **Minor** (v1.1.0)
*   `break: ...` -> Gera versão **Major** (v2.0.0)

## ☸️ Operação (SRE Cheatsheet)

### Monitorando Rollout em Tempo Real
```bash
kubectl argo rollouts get rollout node-k8s-app -w
```

### Rollback em Emergência
Em ambientes GitOps, o botão de Rollback da UI pode ser bloqueado pelo Auto-Sync.
> 📖 [Leia o Guia de Rollback GitOps](./GITOPS_ROLLBACK_GUIDE.md) para saber como proceder.

### Acessando Dashboards (Comandos de Port-Forward)

**ArgoCD (Credenciais: admin / inicial)**
```bash
# Obter senha inicial do admin (Linux/MacOS/Bash)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Obter senha inicial do admin (Windows PowerShell)
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}")))

# Port-forward
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

# Grafana (Dashboards SRE)
kubectl port-forward -n node-k8s-app svc/grafana 3004:80
```

---
*Este projeto serve como um modelo vivo para práticas avançadas de Engenharia de Plataforma.*
