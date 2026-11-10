#!/bin/bash
set -e

echo "=========================================="
echo "🚀 IDP Platform - Deployment Manager"
echo "=========================================="

# Cargar variables de entorno locales si existen (.env está ignorado en Git)
if [ -f ".env" ]; then
  echo "=> Cargando variables desde .env..."
  set -a
  source .env
  set +a
elif [ -f "../../.env" ]; then
  echo "=> Cargando variables desde ../../.env..."
  set -a
  source ../../.env
  set +a
fi

echo "Leyendo topología desde env.yaml..."

ACTION=${1:-apply}

if [ "$ACTION" != "apply" ] && [ "$ACTION" != "destroy" ]; then
  echo "❌ Acción no válida: '$ACTION'. Uso: $0 [apply|destroy]"
  exit 1
fi

echo "Acción seleccionada: $ACTION"

# Función helper para procesar los flags de Terragrunt
procesar_modulo() {
  local var_name=$1
  local module_dir=$2
  local value=$(grep -E "^${var_name}:" env.yaml | awk '{print $2}')
  
  if [ "$value" != "true" ]; then
    echo "[-] $module_dir desactivado. Excluyendo..."
    CMD="$CMD --queue-exclude-dir $module_dir"
  else
    echo "[+] $module_dir activado."
  fi
}

# Helper para reconciliar recursos de KMS en el estado de Terraform
reconciliar_kms() {
  local resource=$1
  local id=$2
  if ! (cd hub && terragrunt state show "$resource" >/dev/null 2>&1); then
    echo "   [i] Reconciliando $resource al estado de Terraform..."
    (cd hub && terragrunt import "$resource" "$id" >/dev/null 2>&1) || true
  fi
}

# ==============================================================================
# Auto-Reconciliación de Cloud KMS (Pre-Apply)
# Google Cloud KMS no permite borrar KeyRings ni llaves. Si ya existen en GCP
# tras un destroy/recreación, los incorporamos al estado automáticamente para
# evitar el error 409 (RESOURCE_ALREADY_EXISTS).
# ==============================================================================
if [ "$ACTION" = "apply" ]; then
  ENABLE_HUB=$(grep -E "^enable_hub:" env.yaml | awk '{print $2}')
  if [ "$ENABLE_HUB" = "true" ] && [ -d "hub" ]; then
    echo ""
    echo "=> [Auto-Fix] Verificando recursos persistentes de Cloud KMS en GCP..."
    PROJECT_ID="idp-architect"
    REGION="us-central1"
    CLUSTER_NAME="gke-hub-cluster"
    KEYRING_ID="projects/${PROJECT_ID}/locations/${REGION}/keyRings/${CLUSTER_NAME}-vault-keyring"
    CRYPTOKEY_ID="${KEYRING_ID}/cryptoKeys/vault-unseal-key"

    reconciliar_kms 'google_kms_key_ring.vault[0]' "$KEYRING_ID"
    reconciliar_kms 'google_kms_crypto_key.vault_unseal[0]' "$CRYPTOKEY_ID"
    echo "   [✓] Recursos de Cloud KMS listos."
  fi
fi

# Construir el comando base
CMD="terragrunt run --all $ACTION --non-interactive"

# Procesar cada módulo
procesar_modulo "enable_networking" "networking"
procesar_modulo "enable_global_lb" "global-lb"
procesar_modulo "enable_hub" "hub"
procesar_modulo "enable_argocd" "argocd"
procesar_modulo "enable_observability" "observability"
procesar_modulo "enable_spoke_cloud_base" "spoke-cloud-base"
procesar_modulo "enable_spoke_base_hybrid" "spoke-base-hybrid"
procesar_modulo "enable_spoke_onprem" "spoke-onprem"
procesar_modulo "enable_spoke_ai" "spoke-ai"
procesar_modulo "enable_spoke_data" "spoke-data"

echo ""
echo "=> Ejecutando comando optimizado:"
echo "   $CMD"
echo "=========================================="

# Ejecutar comando final
eval $CMD

# ==============================================================================
# Post-Apply Automation
# Configuración automática de credenciales de clúster e inyección de seed secret
# ==============================================================================
if [ "$ACTION" = "apply" ]; then
  ENABLE_HUB=$(grep -E "^enable_hub:" env.yaml | awk '{print $2}')
  if [ "$ENABLE_HUB" = "true" ]; then
    echo ""
    echo "=========================================="
    echo "🔧 Configurando acceso y credenciales iniciales..."
    echo "=========================================="
    gcloud container clusters get-credentials gke-hub-cluster --region us-central1 --project idp-architect || true

    if [ -n "$GRAFANA_CLOUD_PROMETHEUS_TOKEN" ]; then
      echo "=> Inyectando Secret semilla de Grafana Cloud en namespace 'vault'..."
      kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -
      kubectl create secret generic grafana-cloud-seed -n vault \
        --from-literal=prometheus_url="${GRAFANA_CLOUD_PROMETHEUS_URL}" \
        --from-literal=prometheus_user="${GRAFANA_CLOUD_PROMETHEUS_USER}" \
        --from-literal=prometheus_token="${GRAFANA_CLOUD_PROMETHEUS_TOKEN}" \
        --dry-run=client -o yaml | kubectl apply -f -
      echo "   [✓] Secret 'grafana-cloud-seed' configurado para el auto-bootstrap de Vault."
    fi

    echo ""
    echo "=========================================="
    echo "🎉 Despliegue completado con éxito."
    echo "=========================================="
    echo "📌 Para acceder a ArgoCD:"
    echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "   Contraseña admin:"
    echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo"
    echo "=========================================="
  fi
fi
