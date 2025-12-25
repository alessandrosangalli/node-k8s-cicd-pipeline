# Walkthrough: Maturidade SRE e Observabilidade 2.0

## Resumo das Entregas

### 1. Versionamento Semântico e CI/CD
Implementamos o **Semantic Release** para automatizar o ciclo de versões.
- **CI/CD**: Refatorado para lidar com releases automáticas, build de imagens versionadas e atualização do GitOps (`kustomization.yaml`).
- **Endpoint /version**: O App agora expõe sua versão real vinda do `package.json`.

### 2. Upgrade Tecnológico
- **Node.js 22 LTS**: Atualizamos a base da aplicação para a versão mais recente e performante.

### 3. Observabilidade 2.0 (Tracing)
Esta é a joia da coroa deste ciclo. Implementamos um pipeline de tracing completo:
- **Instrumentation**: SDK do OpenTelemetry integrado ao código Node.js.
- **OTel Collector**: Agente central para processar telemetria, configurado para receber tráfego em `0.0.0.0`.
- **Grafana Tempo**: Banco de dados de traces de alta performance.
- **Isolamento**: Todos os recursos foram movidos para o namespace `node-k8s-app` com manifestos auto-gerenciados.

## Como Validar na Prática

1. **Acesse a Aplicação**: Gere tráfego acessando o IP externo da API ou via port-forward.
2. **Abra o Grafana**:
   ```bash
   kubectl port-forward svc/grafana 3004:80 -n node-k8s-app
   ```
3. **Explore os Traces**:
   - Vá em **Explore** no Grafana.
   - Selecione o DataSource **Tempo**.
   - Clique na aba **Search**.
   - Escolha o `Service Name: node-k8s-app` e clique em **Run Query**.
   - Clique em um **Trace ID** para ver a cascata da requisição.

> [!NOTE]
> **Correções Técnicas Feitas**:
> - Resolvemos o erro `connection refused` vinculando os receptores do coletor ao `0.0.0.0`.
> - Ajustamos a resolução de DNS usando FQDNs internos do Kubernetes.
> - Estabilizamos o Ingress após a migração de namespace.

---
**Próxima Evolução Sugerida**: Implementar o **Checkov** na pipeline para garantir a segurança de toda essa nova infraestrutura via IaC Scanning.
