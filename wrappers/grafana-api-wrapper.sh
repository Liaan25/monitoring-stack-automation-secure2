#!/bin/bash
# Скрипт-обёртка для безопасной работы с Grafana API и HTTP-проверками.
# Режимы:
#   ds_status_by_name  <grafana_url> <token> <name>
#   ds_create          <grafana_url> <token>         (payload из stdin)
#   ds_update_by_name  <grafana_url> <token> <name> (payload из stdin)
#   ds_list            <grafana_url> <token>
#   ds_get_by_name     <grafana_url> <token> <name>
#   ds_update_by_id    <grafana_url> <token> <id>   (payload из stdin)
#   sa_create          <grafana_url> <user> <pass>  (payload из stdin)
#   sa_list            <grafana_url> <user> <pass>
#   sa_token_create    <grafana_url> <user> <pass> <sa_id> (payload из stdin)
#   http_check         <url> <https|http>

set -euo pipefail

MODE="${1:-}"

log() {
  echo "[GRAFANA_WRAPPER] $*"
}

fail() {
  echo "[GRAFANA_WRAPPER][ERROR] $*" >&2
  exit 1
}

validate_grafana_url() {
  local url="$1"
  # Разрешаем только https://<host>:3000[/...]
  [[ "$url" =~ ^https://[a-zA-Z0-9._-]+:3000(/.*)?$ ]] || fail "Недопустимый grafana_url (ожидается порт 3000): $url"
}

validate_http_local_url() {
  local url="$1"
  [[ "$url" =~ ^https?://127\.0\.0\.1:[0-9]+$ ]] || fail "Недопустимый URL для проверки: $url"
}

validate_token() {
  local token="$1"
  [[ -n "$token" ]] || fail "Пустой токен Grafana"
}

validate_user_pass() {
  local user="$1"
  local pass="$2"
  [[ -n "$user" && -n "$pass" ]] || fail "Пустые учётные данные Grafana"
}

validate_id_numeric() {
  local id="$1"
  [[ "$id" =~ ^[0-9]+$ ]] || fail "Недопустимый ID: $id"
}

main() {
  case "$MODE" in
    ds_status_by_name)
      local url="$2" token="$3" name="$4"
      validate_grafana_url "$url"
      validate_token "$token"
      [[ -n "$name" ]] || fail "Пустое имя datasource"
      curl -k -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $token" \
        "$url/api/datasources/name/$name" || echo "000"
      ;;

    ds_create)
      local url="$2" token="$3"
      validate_grafana_url "$url"
      validate_token "$token"
      local payload
      payload="$(cat)"
      [[ -n "$payload" ]] || fail "Пустой payload для ds_create"
      curl -k -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$url/api/datasources" || echo "000"
      ;;

    ds_update_by_name)
      local url="$2" token="$3" name="$4"
      validate_grafana_url "$url"
      validate_token "$token"
      [[ -n "$name" ]] || fail "Пустое имя datasource"
      local payload
      payload="$(cat)"
      [[ -n "$payload" ]] || fail "Пустой payload для ds_update_by_name"
      curl -k -s -o /dev/null -w "%{http_code}" -X PUT \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$url/api/datasources/name/$name" || echo "000"
      ;;

    ds_list)
      local url="$2" token="$3"
      validate_grafana_url "$url"
      validate_token "$token"
      curl -k -s -H "Authorization: Bearer $token" "$url/api/datasources" || true
      ;;

    ds_get_by_name)
      local url="$2" token="$3" name="$4"
      validate_grafana_url "$url"
      validate_token "$token"
      [[ -n "$name" ]] || fail "Пустое имя datasource"
      curl -k -s -H "Authorization: Bearer $token" "$url/api/datasources/name/$name" || true
      ;;

    ds_update_by_id)
      local url="$2" token="$3" id="$4"
      validate_grafana_url "$url"
      validate_token "$token"
      validate_id_numeric "$id"
      local payload
      payload="$(cat)"
      [[ -n "$payload" ]] || fail "Пустой payload для ds_update_by_id"
      curl -k -s -o /dev/null -w "%{http_code}" -X PUT \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$url/api/datasources/$id" || echo "000"
      ;;

    sa_create)
      local url="$2" user="$3" pass="$4"
      validate_grafana_url "$url"
      validate_user_pass "$user" "$pass"
      local payload
      payload="$(cat)"
      [[ -n "$payload" ]] || fail "Пустой payload для sa_create"
      curl -k -s -X POST -H "Content-Type: application/json" \
        --user "$user:$pass" -d "$payload" \
        -w $'\n''%{http_code}' "$url/api/serviceaccounts/" || true
      ;;

    sa_list)
      local url="$2" user="$3" pass="$4"
      validate_grafana_url "$url"
      validate_user_pass "$user" "$pass"
      curl -k -s -H "Accept: application/json" \
        --user "$user:$pass" \
        -w $'\n''%{http_code}' "$url/api/serviceaccounts/" || true
      ;;

    sa_token_create)
      local url="$2" user="$3" pass="$4" sa_id="$5"
      validate_grafana_url "$url"
      validate_user_pass "$user" "$pass"
      validate_id_numeric "$sa_id"
      local payload
      payload="$(cat)"
      [[ -n "$payload" ]] || fail "Пустой payload для sa_token_create"
      curl -k -s -X POST -H "Content-Type: application/json" \
        --user "$user:$pass" -d "$payload" \
        -w $'\n''%{http_code}' "$url/api/serviceaccounts/$sa_id/tokens" || true
      ;;

    http_check)
      local url="$2" scheme="$3"
      validate_http_local_url "$url"
      if [[ "$scheme" == "https" ]]; then
        curl -4 -k -s --connect-timeout 5 --retry 2 --retry-delay 1 --retry-connrefused -x "" "$url" >/dev/null 2>&1
      else
        curl -4 -s --connect-timeout 5 --retry 2 --retry-delay 1 --retry-connrefused -x "" "$url" >/dev/null 2>&1
      fi
      ;;

    *)
      fail "Неизвестный режим: $MODE"
      ;;
  esac
}

main "$@"


