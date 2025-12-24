---
trigger: always_on
---

Sempre escreva o readme em portugues
Sempre atualize o readme de acordo com o conteúdo do projeto
Não faça soluções com base em achismo sem antes tentar coletar informações para criar algo fundamentado
Sempre faça soluções de acordo com o estado da arte do SRE, GitOps, CI/CD e pipelines modernas
NUNCA execute comandos que modifiquem o cluster Kubernetes (kubectl apply, kubectl delete, kubectl patch, kubectl edit, etc) - todas as mudanças devem ser commitadas no Git e a pipeline CI/CD automatizada faz o deploy via GitOps/ArgoCD