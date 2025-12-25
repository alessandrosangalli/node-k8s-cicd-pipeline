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

### 3. Observabilidade e SRE
Dashboards e métricas tratados como código.
*   **Grafana as Code**: Dashboards provisionados automaticamente via ConfigMaps.
*   **Golden Signals**: Monitoramento nativo de Latência, Tráfego, Erros e Saturação.
*   **Prometheus**: Exposição de métricas de negócio e runtime via endpoint `/metrics`.

### 4. Segurança em Profundidade
*   **IaC Security Scanner (Novo!)**: Uso de **Checkov** para análise estática de segurança em manifestos Kubernetes e arquivos Terraform.
*   **Supply Chain Security**: Escaneamento de vulnerabilidades com **Trivy** no código fonte e na imagem final do container.
*   **Least Privilege**: Containers rodam como usuário não-root (UID 1000).
*   **Hardening**: Uso de `helmet` para headers HTTP seguros e imagem base Alpine para menor superfície de ataque.

## 🛠 Stack Tecnológica

| Componente | Tecnologia | Função |
| :--- | :--- | :--- |
| **Runtime** | Node.js 22 (LTS) | Execução do serviço de alta performance |
| **Observabilidade 2.0** | OpenTelemetry (OTel) | Tracing distribuído e métricas unificadas |
| **Orquestração** | Kubernetes & GKE | Gerenciamento de containers |
| **GitOps** | ArgoCD | Continuous Delivery |
| **Progressive Delivery** | Argo Rollouts | Canary Deployments |
| **Observabilidade** | Prometheus & Grafana | Monitoramento e Alertas |
| **Segurança (IaC)** | Checkov | Static Analysis (Scan Terraform/K8s) |
| **Segurança (App/Image)** | AquaSecurity Trivy | Vulnerability Scanning |
| **Release** | Semantic Release | Versionamento Automático |

## 🚀 Como Executar

### Pré-requisitos
*   Node.js 20+
*   Docker
*   Kubernetes (Minikube/Kind/GKE)
*   **GitOps Ready**: O Sloth CRD e todas as dependências são gerenciados automaticamente via Kustomize.

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
```bash
# ArgoCD
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80
```

---
*Este projeto serve como um modelo vivo para práticas avançadas de Engenharia de Plataforma.*
