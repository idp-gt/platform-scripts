#!/bin/bash
set -e

echo "=========================================="
echo "🚀 IDP Platform - Deployment Manager"
echo "=========================================="
echo "Leyendo topología desde env.yaml..."

ACTION=${1:-apply}

if [ "$ACTION" != "apply" ] && [ "$ACTION" != "destroy" ]; then
  echo "❌ Acción no válida: '$ACTION'. Uso: $0 [apply|destroy]"
  exit 1
fi

echo "Acción seleccionada: $ACTION"

# Función helper para procesar los flags
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
