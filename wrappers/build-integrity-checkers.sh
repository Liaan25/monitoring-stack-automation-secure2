#!/bin/bash
# Генерация лаунчеров с проверкой sha256 для скриптов-обёрток.
# Запускается в Jenkins после git clone, чтобы на каждый коммит
# хеши соответствовали актуальным версиям обёрток.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

create_launcher() {
  local launcher_name="$1"    # например, iptables_launcher.sh
  local wrapper_name="$2"     # например, iptables_wrapper.sh

  local wrapper_path="$SCRIPT_DIR/$wrapper_name"
  local launcher_path="$SCRIPT_DIR/$launcher_name"

  if [[ ! -f "$wrapper_path" ]]; then
    echo "[generate_launchers] Обёртка не найдена: $wrapper_path" >&2
    exit 1
  fi

  # Гарантируем, что сама обёртка исполняемая (на случай, если в репозитории нет +x)
  chmod 700 "$wrapper_path"

  local hash
  hash=$(sha256sum "$wrapper_path" | awk '{print $1}')

  cat > "$launcher_path" <<EOF
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="\$SCRIPT_DIR/$wrapper_name"
EXPECTED_HASH="$hash"

calc_hash=\$(sha256sum "\$WRAPPER" 2>/dev/null | awk '{print \$1}')
if [[ "\$calc_hash" != "\$EXPECTED_HASH" ]]; then
  echo "[SECURITY] Hash mismatch for \$WRAPPER" >&2
  exit 1
fi

exec "\$WRAPPER" "\$@"
EOF

  chmod 700 "$launcher_path"
  echo "[generate_launchers] Лаунчер создан: $launcher_path (hash=$hash)"
}

create_launcher "iptables_launcher.sh" "iptables_wrapper.sh"
create_launcher "rlm_launcher.sh" "rlm_task_wrapper.sh"
create_launcher "grafana_launcher.sh" "grafana_wrapper.sh"
create_launcher "config_writer_launcher.sh" "config_writer.sh"


