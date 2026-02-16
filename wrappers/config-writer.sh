#!/bin/bash
# Скрипт-обёртка для безопасной записи конфигурационных файлов.
# Принимает путь к файлу из белого списка и читает содержимое из stdin.
#
# Использование:
#   config_writer.sh /etc/grafana/grafana.ini <<EOF
#   ...контент...
#   EOF

set -euo pipefail

TARGET_PATH="${1:-}"

log() {
  echo "[CONFIG_WRITER] $*"
}

fail() {
  echo "[CONFIG_WRITER][ERROR] $*" >&2
  exit 1
}

validate_target() {
  local path="$1"
  case "$path" in
    /etc/environment.d/99-monitoring-vars.conf|\
    /opt/vault/conf/agent.hcl|\
    /etc/grafana/grafana.ini|\
    /etc/prometheus/web-config.yml|\
    /etc/prometheus/prometheus.env|\
    /etc/profile.d/harvest.sh|\
    /opt/harvest/harvest.yml|\
    /etc/systemd/system/harvest.service|\
    /etc/prometheus/prometheus.yml|\
    /var/lib/monitoring_deployment_state)
      return 0
      ;;
    *)
      fail "Путь не входит в белый список: $path"
      ;;
  esac
}

main() {
  [[ -n "$TARGET_PATH" ]] || fail "Не задан целевой файл"
  validate_target "$TARGET_PATH"

  local dir
  dir="$(dirname "$TARGET_PATH")"
  mkdir -p "$dir"

  # Пишем stdin в целевой файл
  cat > "$TARGET_PATH"

  log "Файл записан: $TARGET_PATH"
}

main "$@"


