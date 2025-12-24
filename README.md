# Pipeline Kubernetes Estado da Arte

Este projeto demonstra uma pipeline **DevSecOps** de nível profissional para um microserviço Node.js. Ele utiliza as ferramentas mais avançadas do mercado para criar uma arquitetura de deploy robusta, segura, escalável e com entrega progressiva.

## 🚀 Testando o Canary Release (Prova de Fogo)

Para verificar o "Self-Healing" da aplicação:

1.  **Edite `src/app.js`**: Descomente as linhas que simulam erro 500 no endpoint `/`.
2.  **Commit & Push**: Envie a mudança para o GitHub.
    ```bash
    git add .
    git commit -m "feat: simulate failure"
    git push
    ```
3.  **Acompanhe**:
    *   No terminal: `kubectl argo rollouts get rollout node-k8s-app -w`
    *   No Dashboard (Porta 8081): Veja o gráfico de erro subir.
4.  **Resultado**: O Argo detectará a taxa de erro > 1% (nosso limite estrito) e abortará o deploy automaticamente!

## 🏆 Destaques do Projeto (Por que é "Estado da Arte"?)

*   **Entrega Progressiva (Canary Deployments)**: Utiliza **Argo Rollouts** para gerenciar deploys graduais. Em vez de substituir tudo de uma vez, a nova versão recebe tráfego aos poucos (20%, 50%, 100%), permitindo validar a estabilidade antes da conclusão.
*   **GitOps com Kustomize**: Gerenciamento declarativo de ambientes usando **Kustomize**. Estrutura de `base` e `overlays` para gerenciar diferentes configurações (Dev, Staging, Prod) sem duplicar código.
*   **Fluxo GitOps Nativo**: Integração com **ArgoCD** para garantir que o estado do cluster Kubernetes seja sempre idêntico ao que está definido no Git.
*   **Security First (Segurança em Primeiro Lugar)**:
    *   **Trivy**: Escaneamento automatizado de vulnerabilidades no sistema de arquivos e nas camadas da imagem Docker. A pipeline falha automaticamente se encontrar vulnerabilidades `CRITICAL` ou `HIGH`.
    *   **Usuário Não-Root**: O container roda estritamente com o usuário `node` (UID 1000), reduzindo a superfície de ataque.
    *   **Helmet.js**: Implementação de cabeçalhos de segurança HTTP.
*   **Observabilidade como Código (Dashboards as Code)**:
    *   **Grafana Automatizado**: O projeto provisiona automaticamente um dashboard Grafana (`k8s/base/dashboard.yaml`) via ConfigMap.
    *   **Monitoramento Golden Signals**: Visualização imediata de RPS, Taxa de Erro e Distribuição de Tráfego entre Canary/Stable assim que o app sobe.
*   **Observabilidade Avançada**:
    *   **Métricas Prometheus**: Endpoint `/metrics` nativo expondo uso de CPU, memória e contagem de requisições.
    *   **Logging Estruturado**: Utiliza `Winston` com formato JSON em produção (ideal para ELK/Datadog) e formato amigável com cores em desenvolvimento.
*   **Performance & Otimização de Custos (FinOps & SRE)**:
    *   **GKE Autopilot**: Utiliza o modo "Serverless" do GKE para eliminar o "toil" de gerenciamento de nodes e reduzir custos de Control Plane em 100%.
    *   **Custo-Eficiência Estrita**: Arquitetura desenhada para rodar com o menor custo possível no GCP sem comprometer a confiabilidade, utilizando port-forward para ferramentas administrativas (ArgoCD/Grafana).
    *   **PDB (Pod Disruption Budget)**: Garante alta disponibilidade (min-available 50%) durante manutenções automatizadas do Google.
    *   **HPA (Horizontal Pod Autoscaler)**: Escalabilidade dinâmica baseada em métricas reais, permitindo que a infraestrutura encolha em períodos de inatividade.
    *   **Prometheus Otimizado**: Configuração de retenção e recursos ajustada para o "SRE Hierarchy of Needs", focando em métricas críticas com baixo overhead.

## 🛠 Stack Tecnológica

*   **Aplicação**: Node.js 20 (LTS), Express, Winston, Prom-client
*   **CI (Integração Contínua)**: GitHub Actions
*   **CD (Entrega Contínua)**: ArgoCD & Argo Rollouts
*   **Infraestrutura**: Kubernetes, Kustomize
*   **Container**: Docker (GHCR como Registry)
*   **Segurança**: AquaSecurity Trivy

## 🚀 Como Começar

### Pré-requisitos

*   Node.js & npm
*   Docker
*   Cluster Kubernetes (Minikube ou Kind para local)
*   kubectl & kustomize

### Desenvolvimento Local

1.  **Instalar Dependências**
    ```bash
    npm install
    ```

2.  **Executar em Modo Dev** (com hot-reload)
    ```bash
    npm run dev
    ```

3.  **Executar Testes & Lint**
    ```bash
    npm test
    npm run lint
    ```

### 🐳 Build Docker Local

```bash
docker build -t node-k8s-app .
docker run -p 3000:3000 node-k8s-app
```

## ☸️ Deploy no Kubernetes

### 1. Estrutura Kustomize

O projeto utiliza a seguinte estrutura:
- `k8s/base`: Manifestos base (Rollout, Service, HPA, Ingress).
- `k8s/overlays/production`: Customizações específicas para produção (ex: número de réplicas).

Para visualizar os manifestos finais:
```bash
kubectl kustomize k8s/overlays/production
```

### 2. Deploy via ArgoCD

1.  Crie o namespace e instale o ArgoCD no seu cluster.
2.  Aplique o manifesto da aplicação:
    ```bash
    kubectl apply -f argocd/application.yaml
    ```

## ⚙️ Arquitetura da Pipeline (Deep Dive)

### 1. Garantia de Qualidade e Segurança (CI)
*   **Linting**: Validação do estilo de código com ESLint.
*   **Testes**: Execução de testes unitários e de integração com Jest.
*   **Scan de Código**: O Trivy varre o sistema de arquivos em busca de dependências vulneráveis.

### 2. Build e Otimização de Imagem
*   A imagem é construída usando o Dockerfile multi-estágio.
*   O `npm` é atualizado globalmente e o `dumb-init` é instalado para gerenciar corretamente os processos (PID 1).
*   Um segundo scan do Trivy é feito diretamente na imagem final antes do push para o GHCR.

### 3. Entrega progressiva (GitOps)
Em vez de usar `kubectl apply`, a pipeline atualiza a versão da imagem no `k8s/base/kustomization.yaml`.
O **ArgoCD** detecta essa mudança e o **Argo Rollouts** assume o controle:
1.  Inicia o novo set de Pods.
2.  Redireciona 20% do tráfego.
3.  Pausa por 1 minuto para observação.
4.  Aumenta para 50%, depois 100%.

Isso garante que, se houver um erro crítico, o impacto seja minimizado e o rollback seja imediato.

---

## 📖 Guia de Operação (Cloud Shell)

Este guia contém os comandos essenciais para operar e monitorar o projeto diretamente do Google Cloud Shell.

### 1. Acesso ao Cluster e IPs
```bash
# Conectar o kubectl ao seu cluster GKE
gcloud container clusters get-credentials gke-node-k8s-cluster --region us-central1

# Obter o IP externo da aplicação (Ingress)
kubectl get ingress node-app-ingress
```

### 2. Gerenciamento do ArgoCD
```bash
# Obter o acesso ao ArgoCD (Via Port-Forward - Segurança & Economia)
# Não expomos ferramentas sensíveis via IP público por boas práticas de segurança e FinOps.
kubectl port-forward -n argocd svc/argocd-server 8080:443
# Acesse: https://localhost:8080 (User: admin)
```

### 3. Operação de Rollouts (Canary)
```bash
# Instalar o plugin do Argo Rollouts no Cloud Shell (se não tiver)
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x ./kubectl-argo-rollouts-linux-amd64
sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# Ver o status do deploy em tempo real (Visão de Linha do Tempo)
kubectl argo rollouts get rollout node-k8s-app -w

# Abrir o Dashboard Visual (Clique em Web Preview -> Port 8080)
kubectl argo rollouts dashboard

# Comandos de Emergência
kubectl argo rollouts retry rollout node-k8s-app   # Tentar novamente um deploy falho
kubectl argo rollouts abort rollout node-k8s-app   # Cancelar deploy e voltar para estável
kubectl argo rollouts promote rollout node-k8s-app # Pular steps e ir para 100% agora
```

### 4. Observabilidade (Prometheus)
```bash
# Abrir o painel do Prometheus (Web Preview -> Port 9090)
kubectl port-forward -n monitoring deployment/prometheus-server 9090:9090

# Testar se o Prometheus está coletando métricas (via terminal)
curl -G 'http://prometheus-server.monitoring.svc.cluster.local/api/v1/query' \
    --data-urlencode 'query=http_requests_total'
```

### 5. Manutenção e GitOps
```bash
# Aplicar mudanças de Bootstrap (GitOps Root App)
kubectl apply -f argocd/bootstrap-app.yaml

# Ver logs da aplicação em tempo real
kubectl logs -f -l app=node-k8s-app --all-containers

# Ver eventos de erro no cluster
kubectl get events --sort-by='.lastTimestamp'
```

---
*Este projeto é parte de um ecossistema de aprendizado em Engenharia de Plataforma e SRE.*
