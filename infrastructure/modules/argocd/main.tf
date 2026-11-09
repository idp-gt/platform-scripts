# Terraform block removed to avoid duplication with Terragrunt

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "6.7.11" # Versión recomendada y estable

  values = [
    <<EOF
server:
  service:
    type: ClusterIP

configs:
  params:
    server.insecure: false

# Habilitar métricas para Prometheus / Grafana Alloy
controller:
  metrics:
    enabled: true
    service:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8082"

server:
  metrics:
    enabled: true
    service:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8083"

repoServer:
  metrics:
    enabled: true
    service:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8084"

applicationSet:
  metrics:
    enabled: true

notifications:
  metrics:
    enabled: true
EOF
  ]
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
