# Guia de Rollback em GitOps

Em um ambiente **GitOps**, o Git é a única fonte de verdade. Isso significa que se você tentar mudar o estado do cluster manualmente (ex: clicando em "Rollback" na UI do Argo Rollouts), o ArgoCD vai detectar que o cluster está diferente do Git e vai "corrigir" (Self-Heal) a mudança, revertendo o seu rollback imediatamente.

## Como fazer Rollback Corretamente?

Existem duas formas de gerenciar incidentes neste cenário:

### 1. O Jeito GitOps ("The Right Way") - Definitivo

Se a versão `v1.1.0` está com problemas, você deve dizer ao Git que a versão correta volta a ser a `v1.0.0`.

1.  **Reverta o Commit**:
    ```bash
    git revert HEAD -m "revert: rollback to v1.0.0 due to incident #123"
    git push
    ```
2.  **Aguarde**: O ArgoCD vai detectar o novo commit e aplicar o estado anterior. O Argo Rollouts vai executar o rollback logicamente.

**Prós**:
*   Histórico auditável (quem fez o rollback e por que).
*   Estado consistente (Git = Cluster).

**Contras**:
*   Pode levar alguns minutos (Pipeline + Sync).

### 2. O Jeito Break-Glass ("Emergência") - Rápido

Se o incêndio é grande e você precisa estancar o sangramento **AGORA** via UI:

1.  **Desative o Self-Heal do ArgoCD**:
    *   Vá na UI do ArgoCD > Application > Details > Sync Policy > Disable Auto-Sync.
    *   *Ou via CLI*: `kubectl patch app node-k8s-app -n argocd --type merge -p '{"spec":{"syncPolicy":{"automated":null}}}'`
2.  **Execute o Rollback na UI do Argo Rollouts**:
    *   Agora o botão de Rollback vai funcionar e o ArgoCD vai ficar com status "OutOfSync" (o que é esperado durante um incidente).
3.  **Pós-Incidente (Post-Mortem)**:
    *   Faça o `git revert` no repositório para oficializar a volta.
    *   Reative o Auto-Sync do ArgoCD.

## Ajuste na Configuração (Opcional)

Se quiser permitir que a UI do Argo Rollouts tenha precedência temporária sem desativar tudo, é complexo configurar, pois viola o princípio do GitOps. A recomendação do mercado é seguir o **Opção 1** para maturidade, ou ter scripts de automação para a **Opção 2**.
