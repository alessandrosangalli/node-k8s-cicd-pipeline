# Pipeline Kubernetes Estado da Arte

Este projeto demonstra uma pipeline **DevSecOps** de nível profissional para um microserviço Node.js. Ele utiliza as ferramentas mais avançadas do mercado para criar uma arquitetura de deploy robusta, segura, escalável e com entrega progressiva.

## 🏆 Destaques do Projeto (Por que é "Estado da Arte"?)

*   **Entrega Progressiva (Canary Deployments)**: Utiliza **Argo Rollouts** para gerenciar deploys graduais. Em vez de substituir tudo de uma vez, a nova versão recebe tráfego aos poucos (20%, 50%, 100%), permitindo validar a estabilidade antes da conclusão.
*   **GitOps com Kustomize**: Gerenciamento declarativo de ambientes usando **Kustomize**. Estrutura de `base` e `overlays` para gerenciar diferentes configurações (Dev, Staging, Prod) sem duplicar código.
*   **Fluxo GitOps Nativo**: Integração com **ArgoCD** para garantir que o estado do cluster Kubernetes seja sempre idêntico ao que está definido no Git.
*   **Security First (Segurança em Primeiro Lugar)**:
    *   **Trivy**: Escaneamento automatizado de vulnerabilidades no sistema de arquivos e nas camadas da imagem Docker. A pipeline falha automaticamente se encontrar vulnerabilidades `CRITICAL` ou `HIGH`.
    *   **Usuário Não-Root**: O container roda estritamente com o usuário `node` (UID 1000), reduzindo a superfície de ataque.
    *   **Helmet.js**: Implementação de cabeçalhos de segurança HTTP.
*   **Observabilidade Avançada**:
    *   **Métricas Prometheus**: Endpoint `/metrics` nativo expondo uso de CPU, memória e contagem de requisições.
    *   **Logging Estruturado**: Utiliza `Winston` com formato JSON em produção (ideal para ELK/Datadog) e formato amigável com cores em desenvolvimento.
*   **Performance & Escalabilidade**:
    *   **HPA (Horizontal Pod Autoscaler)**: Escalabilidade automática baseada no uso de CPU.
    *   **Builds Multi-estágio**: Dockerfile otimizado para cache e tamanho reduzido da imagem final.

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
