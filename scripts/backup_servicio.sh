#!/usr/bin/env bash
set -euo pipefail

backup_root="${BACKUP_ROOT:-/backup/servicio-aso}"
source_data="${SOURCE_DATA:-/srv/grupo_asir}"
source_config="${SOURCE_CONFIG:-/etc/samba/smb.conf}"
[[ -d "$source_data" ]] || { echo "ERROR: faltan datos: $source_data" >&2; exit 1; }
[[ -f "$source_config" ]] || { echo "ERROR: falta configuracion: $source_config" >&2; exit 1; }
command -v rsync >/dev/null || { echo "ERROR: instala rsync" >&2; exit 1; }

# Impide incluir el destino dentro del origen y copiarlo recursivamente.
source_real="$(realpath "$source_data")"
backup_real="$(realpath -m "$backup_root")"
if [[ "$source_real" == / || "$backup_real" == "$source_real" || "$backup_real" == "$source_real/"* ]]; then
  echo "ERROR: el destino debe estar fuera del directorio de datos" >&2
  exit 1
fi
mkdir -p "$backup_root"
umask 077
dest="$(mktemp -d "${backup_root}/$(date +%Y-%m-%d_%H%M%S)-XXXXXX")"
trap 'echo "ERROR: copia incompleta; revisar $dest" >&2' ERR
mkdir "$dest/datos" "$dest/config"
echo "Iniciando copia en $dest"
rsync -aHAX "$source_data"/ "$dest/datos"/
cp -a "$source_config" "$dest/config/"

{
  echo "fecha=$(date -Is)"
  echo "origen_datos=$source_data"
  echo "origen_config=$source_config"
  echo "destino=$dest"
} > "$dest/backup.log"

echo "Copia terminada: $dest"
