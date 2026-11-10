resource "helm_release" "grafana_alloy" {
  name             = "grafana-alloy"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "alloy"
  version          = "1.6.1"
  namespace        = var.namespace
  create_namespace = true
  wait             = false

  values = [
    <<EOF
controller:
  type: deployment
  replicas: 1
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 250m
      memory: 256Mi

alloy:
  extraEnv:
    - name: GRAFANA_CLOUD_PROMETHEUS_USER
      valueFrom:
        secretKeyRef:
          name: grafana-cloud-credentials
          key: GRAFANA_CLOUD_PROMETHEUS_USER
    - name: GRAFANA_CLOUD_PROMETHEUS_TOKEN
      valueFrom:
        secretKeyRef:
          name: grafana-cloud-credentials
          key: GRAFANA_CLOUD_PROMETHEUS_TOKEN

  configMap:
    content: |
      // 1. Scrape Argo CD Application Controller (Sincronizaciones, Salud, GitOps)
      prometheus.scrape "argocd_controller" {
        targets = [
          {"__address__" = "argocd-application-controller-metrics.argocd.svc.cluster.local:8082"},
        ]
        metrics_path    = "/metrics"
        scrape_interval = "${var.scrape_interval}"
        forward_to      = [prometheus.remote_write.grafana_cloud.receiver]
      }

      // 2. Scrape Argo CD API Server (Latencias, peticiones HTTP, sesiones)
      prometheus.scrape "argocd_server" {
        targets = [
          {"__address__" = "argocd-server-metrics.argocd.svc.cluster.local:8083"},
        ]
        metrics_path    = "/metrics"
        scrape_interval = "${var.scrape_interval}"
        forward_to      = [prometheus.remote_write.grafana_cloud.receiver]
      }

      // 3. Scrape Argo CD Repo Server (Tiempos de Git, generación de manifiestos)
      prometheus.scrape "argocd_repo_server" {
        targets = [
          {"__address__" = "argocd-repo-server-metrics.argocd.svc.cluster.local:8084"},
        ]
        metrics_path    = "/metrics"
        scrape_interval = "${var.scrape_interval}"
        forward_to      = [prometheus.remote_write.grafana_cloud.receiver]
      }

      // 4. Scrape Argo CD ApplicationSet Controller
      prometheus.scrape "argocd_applicationset" {
        targets = [
          {"__address__" = "argocd-applicationset-controller-metrics.argocd.svc.cluster.local:8080"},
        ]
        metrics_path    = "/metrics"
        scrape_interval = "${var.scrape_interval}"
        forward_to      = [prometheus.remote_write.grafana_cloud.receiver]
      }

      // 5. Scrape Argo CD Notifications Controller
      prometheus.scrape "argocd_notifications" {
        targets = [
          {"__address__" = "argocd-notifications-controller-metrics.argocd.svc.cluster.local:9001"},
        ]
        metrics_path    = "/metrics"
        scrape_interval = "${var.scrape_interval}"
        forward_to      = [prometheus.remote_write.grafana_cloud.receiver]
      }

      // 5. Envío seguro por HTTPS hacia Grafana Cloud (Egress vía Cloud NAT)
      prometheus.remote_write "grafana_cloud" {
        endpoint {
          url = "${var.grafana_cloud_prometheus_url}"
          basic_auth {
            username = sys.env("GRAFANA_CLOUD_PROMETHEUS_USER")
            password = sys.env("GRAFANA_CLOUD_PROMETHEUS_TOKEN")
          }
        }
      }
EOF
  ]
}
