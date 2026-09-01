# Terraform block removed to avoid duplication with Terragrunt

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "6.7.11" # Versión recomendada y estable

  # Configuraciones por defecto para ArgoCD en el Hub
  set {
    name  = "server.service.type"
    value = "ClusterIP" # Se expone luego vía Ingress/Gateway API
  }

  set {
    name  = "configs.params.server\\.insecure"
    value = "true" # Si el TLS termina en el Ingress
  }
}

resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = "argocd"
  version    = "1.6.2"

  depends_on = [helm_release.argocd]

  values = [
    <<EOF
applications:
  - name: platform-bootstrap
    namespace: argocd
    project: default
    source:
      repoURL: https://github.com/idp-gt/platform-scripts.git
      targetRevision: main
      path: gitops/platform
      directory:
        recurse: false
    destination:
      server: https://kubernetes.default.svc
      namespace: argocd
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
EOF
  ]
}
