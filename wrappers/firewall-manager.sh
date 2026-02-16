#!/bin/bash
# Скрипт-обёртка для настройки iptables под мониторинг.
# Выполняет базовую валидацию параметров (белые списки портов/формат IP)
# и применяет правила, эквивалентные функции configure_iptables
# из deploy_monitoring_script.sh.

set -euo pipefail

PROMETHEUS_PORT="${1:-9090}"
GRAFANA_PORT="${2:-3000}"
HARVEST_UNIX_PORT="${3:-12991}"
HARVEST_NETAPP_PORT="${4:-12990}"
SERVER_IP="${5:-}"

log() {
  echo "[IPTABLES_WRAPPER] $*"
}

fail() {
  echo "[IPTABLES_WRAPPER][ERROR] $*" >&2
  exit 1
}

validate_port() {
  local port="$1"
  # Разрешаем только числовые порты из диапазона 1-65535
  [[ "$port" =~ ^[0-9]+$ ]] || fail "Недопустимый порт (не число): $port"
  if (( port < 1 || port > 65535 )); then
    fail "Недопустимый порт (вне диапазона 1-65535): $port"
  fi
}

validate_ip() {
  local ip="$1"
  # Простейшая проверка IPv4, чтобы отсечь заведомо неверные значения
  [[ -z "$ip" ]] && return 0
  if ! [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    fail "Недопустимый формат IP: $ip"
  fi
}

main() {
  validate_port "$PROMETHEUS_PORT"
  validate_port "$GRAFANA_PORT"
  validate_port "$HARVEST_UNIX_PORT"
  validate_port "$HARVEST_NETAPP_PORT"
  validate_ip "$SERVER_IP"

  log "Настройка iptables: Prometheus=$PROMETHEUS_PORT, Grafana=$GRAFANA_PORT, HarvestUnix=$HARVEST_UNIX_PORT, HarvestNetApp=$HARVEST_NETAPP_PORT, ServerIP=${SERVER_IP:-<empty>}"

  # Ограничиваем доступ к Prometheus: только localhost и IP сервера
  if ! /usr/sbin/iptables -C INPUT -p tcp -s 127.0.0.1 --dport "$PROMETHEUS_PORT" -j ACCEPT 2>/dev/null; then
    /usr/sbin/iptables -I INPUT 1 -p tcp -s 127.0.0.1 --dport "$PROMETHEUS_PORT" -j ACCEPT
    log "Разрешен доступ к Prometheus с localhost"
  fi

  if [[ -n "$SERVER_IP" ]] && ! /usr/sbin/iptables -C INPUT -p tcp -s "$SERVER_IP" --dport "$PROMETHEUS_PORT" -j ACCEPT 2>/dev/null; then
    /usr/sbin/iptables -I INPUT 1 -p tcp -s "$SERVER_IP" --dport "$PROMETHEUS_PORT" -j ACCEPT
    log "Разрешен доступ к Prometheus с IP сервера ($SERVER_IP)"
  fi

  if ! /usr/sbin/iptables -C INPUT -p tcp --dport "$PROMETHEUS_PORT" -j REJECT 2>/dev/null; then
    /usr/sbin/iptables -I INPUT 3 -p tcp --dport "$PROMETHEUS_PORT" -j REJECT
    log "Закрыт доступ к Prometheus для внешних адресов (IPv4)"
  fi

  # Аналогично для IPv6, если доступен ip6tables
  if command -v ip6tables &> /dev/null; then
    if ! /usr/sbin/ip6tables -C INPUT -p tcp -s ::1 --dport "$PROMETHEUS_PORT" -j ACCEPT 2>/dev/null; then
      /usr/sbin/ip6tables -I INPUT 1 -p tcp -s ::1 --dport "$PROMETHEUS_PORT" -j ACCEPT
      log "Разрешен доступ к Prometheus с IPv6 localhost (::1)"
    fi
    if ! /usr/sbin/ip6tables -C INPUT -p tcp --dport "$PROMETHEUS_PORT" -j REJECT 2>/dev/null; then
      /usr/sbin/ip6tables -I INPUT 2 -p tcp --dport "$PROMETHEUS_PORT" -j REJECT
      log "Закрыт доступ к Prometheus для внешних адресов (IPv6)"
    fi
  fi

  # Grafana и Harvest оставляем доступными
  local other_ports=("$GRAFANA_PORT" "$HARVEST_UNIX_PORT" "$HARVEST_NETAPP_PORT")
  local port
  for port in "${other_ports[@]}"; do
    validate_port "$port"
    if ! /usr/sbin/iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null; then
      /usr/sbin/iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
      log "Открыт порт TCP $port"
    else
      log "Порт TCP $port уже открыт"
    fi
  done

  # Диапазон портов 13000-14000 для Harvest
  if ! /usr/sbin/iptables -C INPUT -p tcp --dport 13000:14000 -j ACCEPT 2>/dev/null; then
    /usr/sbin/iptables -A INPUT -p tcp --dport 13000:14000 -j ACCEPT
    log "Открыт диапазон портов TCP 13000-14000 для Harvest"
  fi

  if command -v iptables-save &> /dev/null; then
    mkdir -p /etc/sysconfig
    /usr/sbin/iptables-save > /etc/sysconfig/iptables 2>/dev/null || {
      log "Не удалось сохранить правила iptables (iptables-save завершился с ошибкой)"
    }
  fi

  log "Настройка iptables завершена (обёртка)"
}

main "$@"


