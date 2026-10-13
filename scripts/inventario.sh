#!/usr/bin/env bash
set -euo pipefail

echo "# Inventario del sistema"
echo
echo "Fecha: $(date -Is)"
echo "Host: $(hostname -f 2>/dev/null || hostname)"
echo

run() {
  local title="$1"
  shift
  echo "## $title"
  echo
  echo '```text'
  "$@" 2>&1 || true
  echo '```'
  echo
}

run "CPU" lscpu
run "Memoria" free -h
run "Discos" lsblk
run "Red" ip -br addr
run "Rutas" ip route
run "Espacio" df -h

if command -v pveversion >/dev/null 2>&1; then
  run "Proxmox" pveversion
fi
