#!/bin/bash
# Este script asume que has ejecutado `terragrunt apply` en el módulo de On-Premise
# y usa sus outputs para generar el archivo inventory.ini estático para Kubespray.

set -e

TERRAGRUNT_DIR="../../infrastructure/environments/dev/spoke-onprem"
INVENTORY_FILE="inventory/onprem-cluster/inventory.ini"

echo "Leyendo outputs de Terraform/Terragrunt..."
cd $TERRAGRUNT_DIR
MASTER_IPS=$(terragrunt output -json master_ips | jq -r '.[]')
WORKER_IPS=$(terragrunt output -json worker_ips | jq -r '.[]')
API_VIP=$(terragrunt output -raw api_server_vip)
cd - > /dev/null

echo "Generando $INVENTORY_FILE..."

cat <<EOF > $INVENTORY_FILE
[all]
EOF

INDEX_MASTER=1
for ip in $MASTER_IPS; do
  echo "master-${INDEX_MASTER} ansible_host=${ip} ip=${ip} etcd_member_name=etcd${INDEX_MASTER}" >> $INVENTORY_FILE
  INDEX_MASTER=$((INDEX_MASTER+1))
done

INDEX_WORKER=1
for ip in $WORKER_IPS; do
  echo "worker-${INDEX_WORKER} ansible_host=${ip} ip=${ip}" >> $INVENTORY_FILE
  INDEX_WORKER=$((INDEX_WORKER+1))
done

cat <<EOF >> $INVENTORY_FILE

[kube_control_plane]
EOF
for ((i=1; i<INDEX_MASTER; i++)); do echo "master-$i" >> $INVENTORY_FILE; done

cat <<EOF >> $INVENTORY_FILE

[etcd]
EOF
for ((i=1; i<INDEX_MASTER; i++)); do echo "master-$i" >> $INVENTORY_FILE; done

cat <<EOF >> $INVENTORY_FILE

[kube_node]
EOF
for ((i=1; i<INDEX_WORKER; i++)); do echo "worker-$i" >> $INVENTORY_FILE; done

cat <<EOF >> $INVENTORY_FILE

[k8s_cluster:children]
kube_control_plane
kube_node
EOF

# Inyectar la VIP en las variables
echo "api_server_vip: ${API_VIP}" > inventory/onprem-cluster/group_vars/all/terraform_vip.yml

echo "Inventario generado exitosamente en $INVENTORY_FILE"
