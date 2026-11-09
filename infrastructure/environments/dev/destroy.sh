#!/bin/bash
# Shortcut para destruir la infraestructura activa según env.yaml
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/deploy.sh" destroy "$@"
