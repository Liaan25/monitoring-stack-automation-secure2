#!/bin/bash
# Скрипт-обёртка для работы с RLM API.
# Поддерживает операции:
#   - create_vault_task: создание задачи vault_agent_config
#   - get_vault_status:  получение статуса задачи Vault
#   - create_rpm_task:   создание задачи LINUX_RPM_INSTALLER
#   - get_rpm_status:    получение статуса RPM-задачи
# Параметры (общие):
#   $1 - режим (см. выше)
#   $2 - базовый URL RLM_API_URL (https://... без переменных в sudoers)
#   $3 - токен RLM_TOKEN
# Остальные параметры зависят от режима, а payload передаётся через stdin.

set -euo pipefail

MODE="${1:-}"
RLM_API_URL="${2:-}"
RLM_TOKEN="${3:-}"

# Белый список допустимых базовых URL RLM.
# При необходимости добавьте сюда другие значения, согласованные с ИБ.
ALLOWED_RLM_BASES=(
  "https://simple-api.rlm.apps.prom-terra000049-ebm.ocp.sigma.sbrf.ru"
)

log() {
  echo "[RLM_WRAPPER] $*"
}

fail() {
  echo "[RLM_WRAPPER][ERROR] $*" >&2
  exit 1
}

validate_url_base() {
  local url="$1"
  # Разрешаем только https-ссылки без пробелов и управляющих символов
  [[ "$url" =~ ^https://[a-zA-Z0-9._:-]+(/.*)?$ ]] || fail "Недопустимый RLM_API_URL (формат): $url"

  local allowed=false
  local base
  for base in "${ALLOWED_RLM_BASES[@]}"; do
    if [[ "$url" == "$base" ]]; then
      allowed=true
      break
    fi
  done

  if [[ "$allowed" != true ]]; then
    fail "RLM_API_URL не входит в белый список: $url"
  fi
}

validate_token() {
  local token="$1"
  [[ -n "$token" ]] || fail "Пустой RLM_TOKEN"
}

validate_task_id() {
  local id="$1"
  [[ "$id" =~ ^[0-9]+$ ]] || fail "Недопустимый task_id: $id"
}

create_task() {
  local payload
  payload="$(cat)"
  [[ -n "$payload" ]] || fail "Пустой payload для создания задачи"

  curl -k -s -X POST "${RLM_API_URL}/api/tasks.json" \
    -H "Accept: application/json" \
    -H "Authorization: Token ${RLM_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$payload"
}

get_status() {
  local task_id="$1"
  validate_task_id "$task_id"

  curl -k -s -X GET "${RLM_API_URL}/api/tasks/${task_id}/" \
    -H "Accept: application/json" \
    -H "Authorization: Token ${RLM_TOKEN}" \
    -H "Content-Type: application/json"
}

main() {
  [[ -n "$MODE" ]] || fail "Не указан режим работы обёртки (MODE)"
  validate_url_base "$RLM_API_URL"
  validate_token "$RLM_TOKEN"

  case "$MODE" in
    create_vault_task|create_rpm_task|create_group_task)
      # Все режимы создания задач используют один и тот же POST /api/tasks.json,
      # различается только service/params в payload, которые формирует внешний скрипт.
      create_task
      ;;
    get_vault_status|get_rpm_status|get_group_status)
      # Все режимы получения статуса используют один и тот же GET /api/tasks/<id>/.
      local task_id="${4:-}"
      [[ -n "$task_id" ]] || fail "Не указан task_id для режима $MODE"
      get_status "$task_id"
      ;;
    *)
      fail "Неизвестный режим: $MODE"
      ;;
  esac
}

main "$@"


