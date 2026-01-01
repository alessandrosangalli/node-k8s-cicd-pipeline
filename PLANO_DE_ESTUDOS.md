# Roteiro de Estudos: Engenharia de Plataforma e SRE (Kubernetes & Google Cloud)

Este roteiro foi desenhado para transformar você em um **Engenheiro de Plataforma Especialista**. O foco aqui não é o código da aplicação (NestJS), mas sim todo o ecossistema que suporta, entrega, protege e monitora esse serviço em produção. A aplicação é apenas um detalhe; a sua responsabilidade é a *Plataforma*.

## 1. Infraestrutura como Código (IaC) e Automação
A base de uma plataforma moderna. Nada deve ser criado manualmente no console.

*   **Terraform (O Motor da Infraestrutura):**
    *   **Core:** HCL, State Management (Remoto no GCS), Modules, Lifecycle, Workspaces.
    *   **Provedores:** Domine o `google` provider para criar recursos GCP e o `kubernetes` e `helm` providers para instanciar recursos dentro do cluster.
    *   **Best Practices:** Estrutura de diretórios, separação de concerns, variáveis sensíveis.
    *   **Segurança em IaC:**
        *   **Checkov:** Como escanear seu código Terraform *antes* de aplicar (Pre-commit hooks). Uso de políticas para barrar recursos inseguros (ex: Buckets públicos, K8s sem RBAC).
*   **Gestão de Identidade e Acesso (IAM):**
    *   **Service Accounts:** O que são, quando usar e como limitar (Least Privilege).
    *   **Workload Identity Federation (WIF):** O "Ouro" da segurança. Como permitir que o GitHub Actions fale com a GCP *sem ter chaves JSON salvas*. Entenda OIDC.

## 2. Containerização Avançada
Não é só escrever um Dockerfile, é criar artefatos de produção otimizados.

*   **Otimização de Imagens:**
    *   **Multi-Stage Builds:** Separação radical entre ambiente de build e runtime.
    *   **Distroless Images:** Uso do `gcr.io/distroless/nodejs` para reduzir a superfície de ataque (sem shell, sem package managers).
*   **Security Scanning:**
    *   **Trivy:** Integração no CI para escanear a imagem em busca de CVEs (Common Vulnerabilities and Exposures) antes de subir para o registro.

## 3. Orquestração e Kubernetes (GKE)
O coração da plataforma.

*   **Arquitetura do GKE:**
    *   Control Plane vs Node Pools.
    *   **Spot Instances:** Como usar máquinas "descartáveis" (Preemptible) para economizar até 90% (veja `FINOPS.md`).
    *   **Autoscaling:** Cluster Autoscaler (Infra) vs HPA (Aplicação).
*   **Gerenciamento de Manifestos:**
    *   **Kustomize:** Gestão de múltiplas configurações (Overlays) sem duplicar código YAML. A forma nativa do K8s de gerenciar ambientes.
*   **Recursos Avançados:**
    *   **Service Accounts (K8s) & Workload Identity:** Como pod no K8s ganha permissão para acessar um Bucket ou Banco no GCP (Binding entre KSA e GSA).
    *   **Network Policies:** Firewall dentro do cluster.
    *   **Resource Quotas & Limit Ranges:** Protegendo o cluster de "vizinhos barulhentos".

## 4. Supply Chain Security (Segurança da Cadeia de Suprimentos)
Este é o diferencial de um Especialista Security-First.

*   **Binary Authorization:**
    *   Conceito de **"Attestations"** (Atestados).
    *   Como bloquear deployments no GKE se a imagem não foi assinada pela sua Pipeline de CI segura.
*   **Assinatura Digital:**
    *   Uso do **KMS (Key Management Service)** para gerar chaves assimétricas.
    *   Assinatura de imagens no momento do build.
*   **SBOM (Software Bill of Materials):**
    *   Geração de inventário de software para auditoria.

## 5. CI/CD Moderno e GitOps
Esqueça scripts manuais e `kubectl apply` da sua máquina.

*   **Componente de CI (Continuous Integration - GitHub Actions):**
    *   Pipelines complexas com Jobs dependentes.
    *   **Caching:** Otimização de tempo de build.
    *   **Semantic Release:** Versionamento automático baseado na especificação de commits. Geração de Changelog e Tags git sem intervenção humana.
*   **Componente de CD (Continuous Delivery - GitOps):**
    *   **ArgoCD:** O estado desejado vive no Git. O ArgoCD garante que o Cluster reflita o Git.
    *   **Self-Healing:** O ArgoCD corrige "Drifts" (mudanças manuais não autorizadas).
    *   **Estratégias de Rollback:**
        *   *Via Git (Revert Commit):* A forma auditável e correta.
        *   *Break-Glass:* Como desativar o sync automático em emergências (veja `GITOPS_ROLLBACK_GUIDE.md`).


## 6. Engenharia de Caos (Chaos Engineering)
* Injeção de Falhas no CI/CD: O estado da arte exige validar a resiliência proativamente. Integre experimentos de Chaos Engineering (ex: Chaos Mesh ou Gremlin) para matar pods aleatoriamente ou injetar latência de rede durante o processo de deploy em staging, garantindo que suas políticas de tolerância a falhas realmente funcionam.
* Analogia: Se o seu projeto atual é um carro de corrida de última geração, o estado da arte é o sistema de telemetria da Fórmula 1 integrado a um piloto automático inteligente: ele não apenas corre rápido (CI/CD), mas detecta um desgaste microscópico no pneu (Observabilidade), calcula se pode terminar a prova sem trocar (Error Budget) e ajusta a mistura de combustível em milissegundos para evitar a quebra do motor (Self-healing).
* **Guia Prático:** Veja `CHAOS_ENGINEERING.md`.

## 7. Observabilidade e SRE
Como saber se a plataforma está saudável.

*   **OpenTelemetry (O Padrão da Indústria):**
    *   Instrumentação neutra de vendor.
    *   Coleta unificada de **Traces**, **Metrics** e **Logs**.
*   **Monitoramento:**
    *   **Prometheus:** O padrão para armazenar métricas de séries temporais.
    *   **Google Cloud Profiler:** Análise contínua de consumo de CPU/Memória em produção com baixo overhead.
*   **Logging:**
    *   Logs estruturados (JSON) para permitir queries e filtros avançados no Cloud Logging.

## 8. FinOps (Cloud Financial Management)
Engenharia eficiente também é engenharia barata. Baseado no `FINOPS.md`.

*   **Etiquetamento (Labeling Strategy):**
    *   Como taguear recursos (K8s labels e GCP labels) para saber *exatamente* quanto cada time ou projeto custa (`cost-center`, `team`, `environment`).
*   **Showback & Unit Economics:**
    *   Criação de dashboards que correlacionam Custo vs Negócio (ex: Custo por Transação).
    *   Entender se o aumento da fatura de cloud é "ruim" (ineficiência) ou "bom" (crescimento orgânico do negócio).
*   **Predictive Autoscaling (Maturidade Cloud Native):**
    *   **KEDA:** Substituindo HPA reativo por HPA baseado em eventos (Prometheus/HTTP) ou Cronograma.
    *   Gestão de Capacidade Antecipada: Escalar *antes* do cliente chegar (ex: Black Friday).

## 🚀 Plano de Ação para Especialização

Para dominar a Engenharia de Plataforma, siga esta trilha prática no projeto:

1.  **Domine a Infraestrutura:** Destrua e recrie o ambiente Terraform (`make infra-destroy` / `make infra-apply` - *cuidado com dados*). Entenda cada linha do `.tf`.
2.  **Segurança da Pipeline:** Tente fazer um commit que viole as regras do **Checkov** ou do **Trivy** e veja a pipeline falhar. Entenda *por que* falhou.
3.  **Observabilidade de Deploy:** Faça uma mudança no código, commite (`fix: changes`) e observe o **ArgoCD** sincronizar. Tente fazer um Rollback via Git.
4.  **Simule um Incidente:** "Mate" um pod manualmente e veja o Kubernetes recriá-lo. Tente mudar uma configuração via `kubectl` e veja o **ArgoCD** desfazer sua mudança (Self-healing).
5.  **Audit FinOps:** Vá ao console de Billing do GCP (se tiver acesso) e tente filtrar os custos pelas Labels definidas no Terraform.

Este repositório não é apenas código; é uma implementação de referência de uma **Plataforma Moderna Baseada em Kubernetes**.
