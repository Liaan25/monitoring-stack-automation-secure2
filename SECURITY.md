### Секьюрити-конспект для службы ИБ

#### 1. Как передаются и хранятся секреты

- Секреты (RLM_TOKEN, Grafana user/pass, Vault-пути и т.п.) берутся из Jenkins Credentials и Vault.
- На целевой сервер они попадают только:
  - в окружение процесса `sudo env ... bash monitoring_deployment.sh`,
  - внутри исполняемого скрипта под root.
- В файлы с состоянием и логи выводятся только технические данные (IP, домен, порты и т.п.), **без секретов и токенов**.
- После завершения основных операций выполняется:
  - `unset RLM_TOKEN GRAFANA_USER GRAFANA_PASSWORD GRAFANA_BEARER_TOKEN`
  - что дополнительно очищает окружение текущего процесса.

#### 2. Белые списки и валидация параметров

- `wrappers/config_writer.sh` — белый список путей, в которые разрешена запись:
  - `/etc/environment.d/99-monitoring-vars.conf`
  - `/opt/vault/conf/agent.hcl`
  - `/etc/grafana/grafana.ini`
  - `/etc/prometheus/web-config.yml`
  - `/etc/prometheus/prometheus.env`
  - `/etc/profile.d/harvest.sh`
  - `/opt/harvest/harvest.yml`
  - `/etc/systemd/system/harvest.service`
  - `/etc/prometheus/prometheus.yml`
  - `/var/lib/monitoring_deployment_state`
  Любой другой путь → немедленная ошибка.

- `wrappers/iptables_wrapper.sh`:
  - валидирует порты (1–65535) и формат IP (IPv4),
  - настраивает только строго определённые правила для Prometheus/Grafana/Harvest и диапазона 13000–14000,
  - использует явные пути `/usr/sbin/iptables`, `/usr/sbin/ip6tables`, `/usr/sbin/iptables-save`.

- `wrappers/rlm_task_wrapper.sh`:
  - разрешает только обращения к RLM API по whitelisted URL:
    - сейчас: `https://api.rlm.sbrf.ru`
  - проверяет формат URL и числовой `task_id`,
  - поддерживает только два типа операций:
    - `POST /api/tasks.json` (создание задач),
    - `GET /api/tasks/<id>/` (статусы задач).

- `wrappers/grafana_wrapper.sh`:
  - разрешает только `grafana_url` вида `https://<host>:3000` (порт 3000 фиксирован),
  - поддерживает ограниченный набор операций:
    - datasources: `GET/POST/PUT /api/datasources*`,
    - service accounts: `GET/POST /api/serviceaccounts*`,
    - локальные HTTP-проверки: только `http(s)://127.0.0.1:<port>`.

#### 3. Какие curl разрешены (через обёртки)

- **RLM (`wrappers/rlm_task_wrapper.sh`)**:
  - `POST ${RLM_API_URL}/api/tasks.json` — создание задач Vault и RPM.
  - `GET  ${RLM_API_URL}/api/tasks/<id>/` — получение статуса задач.
  - `RLM_API_URL` ограничен whitelist’ом (по FQDN) и формату `https://...`.

- **Grafana (`wrappers/grafana_wrapper.sh`)**:
  - Datasources:
    - `GET  <grafana_url>/api/datasources`
    - `GET  <grafana_url>/api/datasources/name/<name>`
    - `POST <grafana_url>/api/datasources`
    - `PUT  <grafana_url>/api/datasources/name/<name>`
    - `PUT  <grafana_url>/api/datasources/<id>`
  - Service accounts:
    - `POST <grafana_url>/api/serviceaccounts/`
    - `GET  <grafana_url>/api/serviceaccounts/`
    - `POST <grafana_url>/api/serviceaccounts/<id>/tokens`
  - HTTP-проверки:
    - только `curl` к `http(s)://127.0.0.1:<порт>` через режим `http_check`.

Во всех случаях исходный скрипт `deploy_monitoring_script.sh` **не вызывает curl напрямую**:
он использует только вышеуказанные обёртки с жёсткой валидацией параметров и whitelists.

#### 4. Контроль целостности скриптов-обёрток (sha256 + лаунчеры)

- Критичные действия (iptables, RLM, Grafana, запись конфигов) выполняются только через скрипты-обёртки:
  - `wrappers/iptables_wrapper.sh`
  - `wrappers/rlm_task_wrapper.sh`
  - `wrappers/grafana_wrapper.sh`
  - `wrappers/config_writer.sh`
- Для каждой обёртки автоматически генерируется соответствующий лаунчер:
  - `wrappers/iptables_launcher.sh`
  - `wrappers/rlm_launcher.sh`
  - `wrappers/grafana_launcher.sh`
  - `wrappers/config_writer_launcher.sh`
- Генерация лаунчеров выполняется скриптом `wrappers/generate_launchers.sh`, который:
  - считает `sha256sum` исходной обёртки;
  - записывает рассчитанный хеш в константу `EXPECTED_HASH` внутри лаунчера;
  - создаёт исполняемый файл-лаунчер, который:
    - при каждом запуске пересчитывает текущий `sha256` обёртки;
    - сравнивает его с `EXPECTED_HASH`;
    - при несовпадении пишет сообщение `[SECURITY] Hash mismatch ...` и немедленно завершает работу с ошибкой;
    - при совпадении выполняет `exec` оригинальной обёртки.
- В Jenkins пайплайне (этап `prep_clone.sh`) после `git clone` вызывается:
  - `cd deploy-monitoring/wrappers && ./generate_launchers.sh`
  - тем самым на каждый коммит/запуск пайплайна лаунчеры автоматически пересобираются с актуальными sha256.
- На целевом сервере скрипты и лаунчеры устанавливаются, например, в `/opt/monitoring/bin`, а в `sudoers` выдаются права **только** на лаунчеры:
  - `/opt/monitoring/bin/iptables_launcher.sh`
  - `/opt/monitoring/bin/rlm_launcher.sh`
  - `/opt/monitoring/bin/grafana_launcher.sh`
  - `/opt/monitoring/bin/config_writer_launcher.sh`
- Таким образом:
  - пользователь с sudo не может заменить содержимое обёрток, оставив прежние правила в `sudoers` — любая подмена кода будет обнаружена по несоответствию sha256;
  - ИБ может в любой момент:
    - взять версии обёрток из репозитория,
    - пересчитать хеши и убедиться, что они совпадают с ожидаемыми `EXPECTED_HASH` в лаунчерах, установленных на боевом сервере.

#### 5. Ролевая модель KAE и группа `as-admin`

- Весь проект опирается на **динамический идентификатор KAE**, вычисляемый из `NAMESPACE_CI` вида `CIxxxx_CIyyyy`:
  - `KAE=$(echo "$NAMESPACE_CI" | cut -d'_' -f2)` → напр. `CI84324523`.
- На основе `KAE` формируются имена учётных записей мониторинга (создаются через RLM/IDM, **не** этим скриптом):
  - `${KAE}-lnx-mon_sys` – сервисная nologin‑УЗ, под которой работают user‑юниты мониторинга;
  - `${KAE}-lnx-mon_ci` – интерактивная CI/ТУЗ, под которой выполняется Jenkins и ручные операции сопровождения.
- В начале работы `deploy_monitoring_script.sh` выполняет функцию `ensure_monitoring_users_in_as_admin`, которая:
  - для `${KAE}-lnx-mon_sys` и `${KAE}-lnx-mon_ci` по очереди вызывает `ensure_user_in_as_admin`;
  - проверяет, что пользователь уже состоит в группе `as-admin` (через `id ... | grep '\bas-admin\b'`);
  - если нет — создаёт RLM‑задачу `UVS_LINUX_ADD_USERS_GROUP` (service `UVS_LINUX_ADD_USERS_GROUP`) через обёртку RLM;
  - ожидает статус `success` (до 120 попыток с интервалом 10 секунд), иначе завершает скрипт ошибкой.
- Таким образом, **членство обеих УЗ в `as-admin` автоматически обеспечивается через RLM‑сценарий**, без прямого изменения `/etc/group` из скрипта.

Это напрямую следует из методички SberInfra:

- все действия по расширению прав должны выполняться через RLM/IDM;
- группа `as-admin` нужна как для использования скриптов `linuxadm-*`, так и для включения linger через `linuxadm-enable-linger`.

#### 6. User‑юниты systemd под `${KAE}-lnx-mon_sys`

При наличии `KAE` и пользователя `${KAE}-lnx-mon_sys` скрипт переводит мониторинг на **user‑юниты** в пространстве пользователя, вместо системных юнитов в `/etc/systemd/system`:

- Создаются юниты в `~${KAE}-lnx-mon_sys/.config/systemd/user/`:
  - `monitoring-prometheus.service` – запускает `/usr/bin/prometheus` с уже настроенным `prometheus.yml` и `web-config.yml`;
  - `monitoring-grafana.service` – запускает `grafana-server` с текущим `grafana.ini`;
  - `monitoring-harvest.service` – запускает/останавливает Harvest из `/opt/harvest`;
  - `monitoring.target` – единая точка управления стеком (Prometheus + Grafana + Harvest).
- Права на каталоги и файлы Prometheus (конфиги, сертификаты, data‑директория) **переотдаются на `${KAE}-lnx-mon_sys`** в функции
  `adjust_prometheus_permissions_for_mon_sys`, чтобы Prometheus мог работать в режиме user‑юнита без поднятия прав.
- Управление сервисами в целевой модели:

```bash
sudo -u ${KAE}-lnx-mon_sys \
  XDG_RUNTIME_DIR="/run/user/$(id -u ${KAE}-lnx-mon_sys)" \
  systemctl --user daemon-reload

sudo -u ${KAE}-lnx-mon_sys \
  XDG_RUNTIME_DIR="/run/user/$(id -u ${KAE}-lnx-mon_sys)" \
  systemctl --user restart monitoring-prometheus.service monitoring-grafana.service
```

Для корректной работы user‑юнитов соблюдаются требования SberInfra:

- у `${KAE}-lnx-mon_sys` есть домашний каталог и включён linger (`linuxadm-enable-linger ${KAE}-lnx-mon_sys` после добавления в `as-admin`);
- при необходимости `${KAE}-lnx-mon_sys` добавлен в группу `systemd-journal` для чтения логов через `journalctl --user`.

Fallback‑модель (если KAE/`…-mon_sys` нет) – запуск через системные юниты (`prometheus`, `grafana-server`, `harvest`) сохраняется для DEV и переходных стендов.


