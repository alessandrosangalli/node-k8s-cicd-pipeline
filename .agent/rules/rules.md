---
trigger: always_on
---

1 - Sempre escreva o readme em portugues
2 - Sempre atualize o readme de acordo com o conteúdo do projeto
3 - Não faça soluções com base em achismo sem antes tentar coletar informações para criar algo fundamentado
4 - Sempre faça soluções de acordo com o estado da arte do SRE, GitOps, CI/CD e pipelines modernas
5 - NUNCA execute comandos que modifiquem o cluster Kubernetes (kubectl apply, kubectl delete, kubectl patch, kubectl edit, etc) - todas as mudanças devem ser commitadas no Git e a pipeline CI/CD automatizada faz o deploy via GitOps/ArgoCD. Apenas execute comandos que fazem consultas para ajudar na tomada de decisão.
6 - Esse é um projeto de portfólio, sempre leve isso em consideração, ele sempre será uma amostra do meu conhecimento sobre as questões que envolvem o projeto