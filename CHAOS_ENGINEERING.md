# Engenharia de Caos com Chaos Mesh

Este documento descreve como validar a resiliência da plataforma `node-k8s-cicd-pipeline` utilizando o **Chaos Mesh**.

## 1. Visão Geral

A Engenharia de Caos permite simular falhas em produção (ou stage) de forma controlada para garantir que o sistema se recupera automaticamente.

### Ferramenta Escolhida: Chaos Mesh
Utilizamos o Chaos Mesh instalado via Terraform/Helm.
- **Namespace:** `chaos-mesh`
- **Componentes:** `chaos-controller-manager`, `chaos-daemon`, `chaos-dashboard`.

## 2. Experimentos Disponíveis

Os manifestos dos experimentos estão localizados em `k8s/chaos-experiments/`.

### 2.1 Pod Kill (Matar Pods)
Simula a queda de instâncias da aplicação.
- **Arquivo:** `k8s/chaos-experiments/pod-kill.yaml`
- **Ação:** Mata pods aleatórios com label `app: node-k8s-app`.
- **Frequência:** A cada 5 minutos.
- **Objetivo:** Validar se o Kubernetes recria os pods e se o Serviço continua respondendo (Zero Downtime).

### 2.2 Network Latency (Latência de Rede)
Simula lentidão na rede interna.
- **Arquivo:** `k8s/chaos-experiments/network-latency.yaml`
- **Ação:** Injeta 100ms de delay.
- **Duração:** 30 segundos, a cada 10 minutos.
- **Objetivo:** Validar timeouts e retries na comunicação entre serviços.

## 3. Como Executar

### Pré-requisitos
- Cluster GKE rodando.
- Terraform aplicado com sucesso (instala o Chaos Mesh).
- `kubectl` configurado.

### Aplicando um Experimento

```bash
# Aplicar experimento de Pod Kill
kubectl apply -f k8s/chaos-experiments/pod-kill.yaml
```

### Monitorando

Verifique se o experimento está rodando:
```bash
kubectl get podchaos -n chaos-mesh
```

Acompanhe os pods da aplicação sendo recriados:
```bash
kubectl get pods -n node-k8s-app -w
```

### Acessando o Dashboard

Para visualizar graficamente:

```bash
# Encaminhar porta do Dashboard
kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333
```
Acesse `http://localhost:2333` no navegador.

## 4. Integração CI/CD (Futuro)

O próximo passo é integrar estes testes na pipeline do GitHub Actions/ArgoCD.
- **Ideia:** Após o deploy em `staging`, rodar um Job que aplica o `pod-kill.yaml`, roda testes de carga (K6) e verifica se a taxa de erro sobe. Se subir além do threshold, o deploy falha.
