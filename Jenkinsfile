pipeline {
    agent none  // Не выбираем агент глобально - используем разные агенты для CI и CDL

    parameters {
        string(name: 'SERVER_ADDRESS',     defaultValue: params.SERVER_ADDRESS ?: '',     description: 'Адрес сервера для подключения по SSH')
        string(name: 'SSH_CREDENTIALS_ID', defaultValue: params.SSH_CREDENTIALS_ID ?: '', description: 'ID Jenkins Credentials (SSH Username with private key)')
        string(name: 'SEC_MAN_ADDR',       defaultValue: params.SEC_MAN_ADDR ?: '',       description: 'Адрес Vault для SecMan')
        string(name: 'NAMESPACE_CI',       defaultValue: params.NAMESPACE_CI ?: '',       description: 'Namespace для CI в Vault')
        string(name: 'NETAPP_API_ADDR',    defaultValue: params.NETAPP_API_ADDR ?: '',    description: 'FQDN/IP NetApp API (например, cl01-mgmt.example.org)')
        string(name: 'VAULT_AGENT_KV',     defaultValue: params.VAULT_AGENT_KV ?: '',     description: 'Путь KV в Vault для AppRole: secret "vault-agent" с ключами role_id, secret_id')
        string(name: 'RPM_URL_KV',         defaultValue: params.RPM_URL_KV ?: '',         description: 'Путь KV в Vault для RPM URL')
        string(name: 'NETAPP_SSH_KV',      defaultValue: params.NETAPP_SSH_KV ?: '',      description: 'Путь KV в Vault для NetApp SSH')
        string(name: 'GRAFANA_WEB_KV',     defaultValue: params.GRAFANA_WEB_KV ?: '',     description: 'Путь KV в Vault для Grafana Web')
        string(name: 'SBERCA_CERT_KV',     defaultValue: params.SBERCA_CERT_KV ?: '',     description: 'Путь KV в Vault для SberCA Cert')
        string(name: 'ADMIN_EMAIL',        defaultValue: params.ADMIN_EMAIL ?: '',        description: 'Email администратора для сертификатов')
        string(name: 'GRAFANA_PORT',       defaultValue: params.GRAFANA_PORT ?: '3000',   description: 'Порт Grafana')
        string(name: 'PROMETHEUS_PORT',    defaultValue: params.PROMETHEUS_PORT ?: '9090',description: 'Порт Prometheus')
        string(name: 'RLM_API_URL',        defaultValue: params.RLM_API_URL ?: '',        description: 'Базовый URL RLM API (например, https://api.rlm.sbrf.ru)')
        booleanParam(name: 'SKIP_VAULT_INSTALL', defaultValue: false, description: 'Пропустить установку Vault через RLM (использовать уже установленный vault-agent)')
        booleanParam(name: 'SKIP_RPM_INSTALL', defaultValue: false, description: '⚠️ Пропустить установку RPM пакетов (Grafana, Prometheus, Harvest) через RLM - использовать уже установленные пакеты')
        booleanParam(name: 'SKIP_CI_CHECKS', defaultValue: true, description: '⚡ Пропустить CI диагностику (очистка, отладка, проверки сети) - только получение из Vault и развертывание')
        booleanParam(name: 'SKIP_DEPLOYMENT', defaultValue: false, description: '🚫 Пропустить весь CDL этап (копирование и развертывание на сервер) - только CI проверки')
    }

    stages {
        // ========================================================================
        // CI ЭТАП: Подготовка и проверка (clearAgent - чистый агент для сборки)
        // ========================================================================
        
        stage('CI: Очистка workspace и отладка') {
            agent { label "clearAgent&&sbel8&&!static" }
            when {
                expression { params.SKIP_CI_CHECKS != true }
            }
            steps {
                script {
                    // Вычисляем DATE_INSTALL здесь, где есть контекст агента
                    env.DATE_INSTALL = sh(script: "date '+%Y%m%d_%H%M%S'", returnStdout: true).trim()
                    
                    echo "================================================"
                    echo "=== НАЧАЛО ПАЙПЛАЙНА ==="
                    echo "================================================"
                    echo "[INFO] Билд: ${currentBuild.number}"
                    echo "[INFO] DATE_INSTALL: ${env.DATE_INSTALL}"
                    
                    // Очистка workspace от старых временных файлов
                    echo "[INFO] Очистка workspace..."
                    sh '''
                        # Удаляем старые временные файлы
                        rm -f prep_clone*.sh scp_script*.sh verify_script*.sh deploy_script*.sh check_results*.sh cleanup_script*.sh get_domain*.sh get_ip*.sh 2>/dev/null || true
                        rm -f temp_data_cred.json 2>/dev/null || true
                    '''
                    echo "[SUCCESS] Workspace очищен"
                }
            }
        }
        
        stage('CI: Отладка параметров пайплайна') {
            agent { label "clearAgent&&sbel8&&!static" }
            when {
                expression { params.SKIP_CI_CHECKS != true }
            }
            steps {
                script {
                    echo "================================================"
                    echo "=== ПРОВЕРКА ПАРАМЕТРОВ ==="
                    echo "================================================"
                    
                    // Проверка обязательных параметров
                    if (!params.SERVER_ADDRESS?.trim()) {
                        error("❌ Не указан SERVER_ADDRESS")
                    }
                    if (!params.SSH_CREDENTIALS_ID?.trim()) {
                        error("❌ Не указан SSH_CREDENTIALS_ID")
                    }
                    
                    echo "[OK] Параметры проверены"
                    echo "[INFO] Сервер: ${params.SERVER_ADDRESS}"
                }
            }
        }
        
        stage('CI: Информация о коде и окружении') {
            agent { label "clearAgent&&sbel8&&!static" }
            when {
                expression { params.SKIP_CI_CHECKS != true }
            }
            steps {
                script {
                    echo "[INFO] === ИНФОРМАЦИЯ О КОДЕ ==="
                    sh '''
                        git log --oneline -3 2>/dev/null || echo "[INFO] Git история недоступна"
                    '''
                }
            }
        }
        
        stage('CI: Расширенная диагностика сети и сервера') {
            agent { label "clearAgent&&sbel8&&!static" }
            when {
                expression { params.SKIP_CI_CHECKS != true }
            }
            steps {
                script {
                    echo "================================================"
                    echo "=== ДИАГНОСТИКА СЕТИ И СЕРВЕРА ==="
                    echo "================================================"
                    echo "[INFO] Целевой сервер: ${params.SERVER_ADDRESS}"
                    
                    sh '''
                        nslookup ''' + params.SERVER_ADDRESS + ''' 2>/dev/null || {
                            echo "[WARNING] DNS разрешение не удалось"
                        }
                        
                        echo "[INFO] === ПРОВЕРКА PING ==="
                        if command -v ping >/dev/null 2>&1; then
                            ping -c 2 -W 2 ''' + params.SERVER_ADDRESS + ''' 2>/dev/null || echo "[WARNING] Ping недоступен"
                        fi
                        
                        echo "[INFO] === ПРОВЕРКА SSH ПОРТА ==="
                        if command -v nc >/dev/null 2>&1; then
                            timeout 5 nc -zv ''' + params.SERVER_ADDRESS + ''' 22 2>&1 || echo "[INFO] SSH проверка будет выполнена на этапе CDL"
                        fi
                    '''
                    
                    echo "[SUCCESS] CI диагностика завершена"
                }
            }
        }

        stage('CI: Получение данных из Vault') {
            agent { label "clearAgent&&sbel8&&!static" }
            steps {
                script {
                    // Устанавливаем DATE_INSTALL если её ещё нет
                    if (!env.DATE_INSTALL) {
                        env.DATE_INSTALL = sh(script: "date '+%Y%m%d_%H%M%S'", returnStdout: true).trim()
                    }
                    
                    echo "[STEP] Получение данных из Vault"
                    
                    def vaultSecrets = []

                    if (params.VAULT_AGENT_KV?.trim()) {
                        vaultSecrets << [path: params.VAULT_AGENT_KV, secretValues: [
                            [envVar: 'VA_ROLE_ID', vaultKey: 'role_id'],
                            [envVar: 'VA_SECRET_ID', vaultKey: 'secret_id']
                        ]]
                    }
                    if (params.RPM_URL_KV?.trim()) {
                        vaultSecrets << [path: params.RPM_URL_KV, secretValues: [
                            [envVar: 'VA_RPM_HARVEST',    vaultKey: 'harvest'],
                            [envVar: 'VA_RPM_PROMETHEUS', vaultKey: 'prometheus'],
                            [envVar: 'VA_RPM_GRAFANA',    vaultKey: 'grafana']
                        ]]
                    }
                    if (params.NETAPP_SSH_KV?.trim()) {
                        vaultSecrets << [path: params.NETAPP_SSH_KV, secretValues: [
                            [envVar: 'VA_NETAPP_SSH_ADDR', vaultKey: 'addr'],
                            [envVar: 'VA_NETAPP_SSH_USER', vaultKey: 'user'],
                            [envVar: 'VA_NETAPP_SSH_PASS', vaultKey: 'pass']
                        ]]
                    }
                    if (params.GRAFANA_WEB_KV?.trim()) {
                        vaultSecrets << [path: params.GRAFANA_WEB_KV, secretValues: [
                            [envVar: 'VA_GRAFANA_WEB_USER', vaultKey: 'user'],
                            [envVar: 'VA_GRAFANA_WEB_PASS', vaultKey: 'pass']
                        ]]
                    }
                    
                    if (vaultSecrets.isEmpty()) {
                        echo "[WARNING] KV пути не заданы"
                        // Создаем пустой JSON
                        def emptyData = [
                            "vault-agent": [role_id: '', secret_id: ''],
                            "rpm_url": [harvest: '', prometheus: '', grafana: ''],
                            "netapp_ssh": [addr: '', user: '', pass: ''],
                            "grafana_web": [user: '', pass: '']
                        ]
                        writeFile file: 'temp_data_cred.json', text: groovy.json.JsonOutput.toJson(emptyData)
                    } else {
                        try {
                            withVault([
                                configuration: [
                                    vaultUrl: "https://${params.SEC_MAN_ADDR}",
                                    engineVersion: 1,
                                    skipSslVerification: false,
                                    vaultCredentialId: 'vault-agent-dev'
                                ],
                                vaultSecrets: vaultSecrets
                            ]) {
                                
                                def data = [
                                    "vault-agent": [
                                        role_id: (env.VA_ROLE_ID ?: ''),
                                        secret_id: (env.VA_SECRET_ID ?: '')
                                    ],
                                    "rpm_url": [
                                        harvest: (env.VA_RPM_HARVEST ?: ''),
                                        prometheus: (env.VA_RPM_PROMETHEUS ?: ''),
                                        grafana: (env.VA_RPM_GRAFANA ?: '')
                                    ],
                                    "netapp_ssh": [
                                        addr: (env.VA_NETAPP_SSH_ADDR ?: ''),
                                        user: (env.VA_NETAPP_SSH_USER ?: ''),
                                        pass: (env.VA_NETAPP_SSH_PASS ?: '')
                                    ],
                                    "grafana_web": [
                                        user: (env.VA_GRAFANA_WEB_USER ?: ''),
                                        pass: (env.VA_GRAFANA_WEB_PASS ?: '')
                                    ]
                                ]
                                
                                writeFile file: 'temp_data_cred.json', text: groovy.json.JsonOutput.toJson(data)
                            }
                        } catch (Exception e) {
                            echo "[ERROR] Ошибка Vault: ${e.message}"
                            error("Не удалось получить данные из Vault")
                        }
                    }
                    
                    // Проверка файла
                    sh '''
                        [ ! -f "temp_data_cred.json" ] && echo "[ERROR] Файл не создан!" && exit 1
                        
                        if command -v jq >/dev/null 2>&1; then
                            jq empty temp_data_cred.json 2>/dev/null || { echo "[ERROR] Невалидный JSON!"; exit 1; }
                        fi
                    '''
                    
                    // Сохраняем для CDL этапа
                    stash name: 'vault-credentials', includes: 'temp_data_cred.json'
                    
                    echo "[SUCCESS] Данные из Vault получены"
                }
            }
        }

        // ========================================================================
        // CDL ЭТАП: Развертывание (masterLin - агент с полным сетевым доступом)
        // ========================================================================

        stage('CDL: Копирование скрипта на удаленный сервер') {
            agent { label "masterLin&&sbel8&&!static" }
            when {
                expression { params.SKIP_DEPLOYMENT != true }
            }
            steps {
                script {
                    echo "================================================"
                    echo "=== CDL: КОПИРОВАНИЕ НА СЕРВЕР ==="
                    echo "================================================"
                    echo "[INFO] Сервер: ${params.SERVER_ADDRESS}"
                    
                    // КРИТИЧЕСКИ ВАЖНО: Принудительно обновляем репозиторий
                    echo "[INFO] Обновление кода из Git (принудительно)..."
                    
                    // Используем checkout с опциями для принудительной очистки
                    checkout([
                        $class: 'GitSCM',
                        branches: scm.branches,
                        extensions: [
                            [$class: 'CleanBeforeCheckout'],
                            [$class: 'CleanCheckout']
                        ],
                        userRemoteConfigs: scm.userRemoteConfigs
                    ])
                    
                    // Проверяем версию
                    echo "[INFO] Текущая версия репозитория:"
                    sh '''
                        echo "========================================="
                        echo "ВЕРИФИКАЦИЯ ВЕРСИИ КОДА"
                        echo "========================================="
                        git log -1 --oneline
                        echo ""
                        echo "[INFO] Последние 5 коммитов:"
                        git log --oneline -5
                        echo "========================================="
                    '''
                    
                    // Восстанавливаем файл с credentials из stash
                    unstash 'vault-credentials'
                    
                    echo "[STEP] Копирование скрипта и файлов на сервер..."
                    sh '''
                        # Проверка необходимых файлов
                        [ ! -f "deploy_monitoring_script.sh" ] && echo "[ERROR] deploy_monitoring_script.sh не найден!" && exit 1
                        [ ! -d "wrappers" ] && echo "[ERROR] Папка wrappers не найдена!" && exit 1
                        [ ! -f "temp_data_cred.json" ] && echo "[ERROR] temp_data_cred.json не найден!" && exit 1
                        echo "[OK] Все файлы на месте"
                    '''
                    
                    withCredentials([
                        sshUserPrivateKey(credentialsId: params.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')
                    ]) {
                        // Генерируем лаунчеры
                        writeFile file: 'prep_clone.sh', text: '''#!/bin/bash
set -e

# Автоматически генерируем лаунчеры
if [ -f wrappers/generate_launchers.sh ]; then
  /bin/bash wrappers/generate_launchers.sh
fi
'''

                        // Создаем scp_script.sh
                        writeFile file: 'scp_script.sh', text: '''#!/bin/bash
set -e

# Проверяем наличие SSH ключа
if [ ! -f "''' + env.SSH_KEY + '''" ]; then
    echo "[ERROR] SSH ключ не найден"
    exit 1
fi

# Устанавливаем права на ключ
chmod 600 "''' + env.SSH_KEY + '''" 2>/dev/null || true

# 1. ТЕСТИРУЕМ SSH ПОДКЛЮЧЕНИЕ
echo ""
echo "[INFO] Тестируем SSH подключение к серверу..."

SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=30 -o ServerAliveInterval=10 -o ServerAliveCountMax=3 -o BatchMode=yes -o TCPKeepAlive=yes"

if ssh -i "''' + env.SSH_KEY + '''" $SSH_OPTS \
    "''' + env.SSH_USER + '''"@''' + params.SERVER_ADDRESS + ''' \
    "echo '[OK] SSH подключение успешно'"; then
    echo "[OK] SSH подключение работает"
else
    echo "[ERROR] SSH подключение к серверу ''' + params.SERVER_ADDRESS + ''' не удалось"
    echo "[INFO] Проверьте доступность SSH сервиса и сетевое подключение"
    exit 1
fi

# 2. СОЗДАЕМ ДИРЕКТОРИЮ НА УДАЛЕННОМ СЕРВЕРЕ
echo ""
echo "[INFO] Создание рабочей директории..."

if ssh -i "''' + env.SSH_KEY + '''" -o StrictHostKeyChecking=no \
    "''' + env.SSH_USER + '''"@''' + params.SERVER_ADDRESS + ''' \
    "rm -rf /tmp/deploy-monitoring && mkdir -p /tmp/deploy-monitoring"; then
    echo "[OK] Директория создана"
else
    echo "[ERROR] Не удалось создать директорию"
    exit 1
fi

# 3. КОПИРУЕМ ФАЙЛЫ
echo ""
echo "[INFO] Копирование файлов на сервер..."

if scp -q -i "''' + env.SSH_KEY + '''" -o StrictHostKeyChecking=no \
    deploy_monitoring_script.sh \
    "''' + env.SSH_USER + '''"@''' + params.SERVER_ADDRESS + ''':/tmp/deploy-monitoring/deploy_monitoring_script.sh; then
    echo "[OK] Скрипт скопирован"
else
    echo "[ERROR] Не удалось скопировать скрипт"
    exit 1
fi

if scp -q -i "''' + env.SSH_KEY + '''" -o StrictHostKeyChecking=no -r \
    wrappers \
    "''' + env.SSH_USER + '''"@''' + params.SERVER_ADDRESS + ''':/tmp/deploy-monitoring/; then
    echo "[OK] Wrappers скопированы"
else
    echo "[ERROR] Не удалось скопировать wrappers"
    exit 1
fi

if scp -q -i "''' + env.SSH_KEY + '''" -o StrictHostKeyChecking=no \
    temp_data_cred.json \
    "''' + env.SSH_USER + '''"@''' + params.SERVER_ADDRESS + ''':/tmp/; then
    echo "[OK] Credentials скопированы"
else
    echo "[ERROR] Не удалось скопировать credentials"
    exit 1
fi

echo ""
echo "[SUCCESS] Все файлы скопированы на сервер"
'''

                        // Создаем verify_script.sh
                        writeFile file: 'verify_script.sh', text: '''#!/bin/bash
set -e

echo "[INFO] Проверка скопированных файлов..."

ssh -i "''' + env.SSH_KEY + '''" -o StrictHostKeyChecking=no \
    "''' + env.SSH_USER + '''"@''' + params.SERVER_ADDRESS + ''' << 'REMOTE_EOF'

[ ! -f "/tmp/deploy-monitoring/deploy_monitoring_script.sh" ] && echo "[ERROR] Скрипт не найден!" && exit 1
[ ! -d "/tmp/deploy-monitoring/wrappers" ] && echo "[ERROR] Wrappers не найдены!" && exit 1
[ ! -f "/tmp/temp_data_cred.json" ] && echo "[ERROR] Credentials не найдены!" && exit 1

echo "[OK] Все файлы на месте"
REMOTE_EOF
'''
                        sh 'chmod +x prep_clone.sh scp_script.sh verify_script.sh'
                        
                        withEnv(['SSH_KEY=' + env.SSH_KEY, 'SSH_USER=' + env.SSH_USER]) {
                            sh './prep_clone.sh'
                            
                            // Retry логика
                            def maxRetries = 3
                            def retryDelay = 10
                            def lastError = null
                            
                            for (def attempt = 1; attempt <= maxRetries; attempt++) {
                                try {
                                    if (attempt > 1) echo "[INFO] Попытка $attempt из $maxRetries..."
                                    sh './scp_script.sh'
                                    lastError = null
                                    break
                                } catch (Exception e) {
                                    lastError = e
                                    if (attempt < maxRetries) {
                                        echo "[WARNING] Попытка не удалась, повтор через $retryDelay сек..."
                                        sleep(time: retryDelay, unit: 'SECONDS')
                                    }
                                }
                            }
                            
                            if (lastError) {
                                error("Ошибка копирования после $maxRetries попыток: ${lastError.message}")
                            }
                            
                            sh './verify_script.sh'
                        }
                        
                        sh 'rm -f prep_clone.sh scp_script.sh verify_script.sh'
                    }
                    echo "[SUCCESS] Репозиторий успешно скопирован на сервер ${params.SERVER_ADDRESS}"
                }
            }
        }

        stage('CDL: Выполнение развертывания') {
            agent { label "masterLin&&sbel8&&!static" }
            when {
                expression { params.SKIP_DEPLOYMENT != true }
            }
            steps {
                script {
                    echo "[STEP] Запуск развертывания на удаленном сервере..."
                    
                    // Восстанавливаем credentials из stash (если нужно)
                    unstash 'vault-credentials'
                    
                    withCredentials([
                        sshUserPrivateKey(credentialsId: params.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
                        string(credentialsId: 'rlm-token', variable: 'RLM_TOKEN')
                    ]) {
                        def scriptTpl = '''#!/bin/bash
ssh -i "$SSH_KEY" -q -o StrictHostKeyChecking=no -o BatchMode=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 "$SSH_USER"@__SERVER_ADDRESS__ RLM_TOKEN="$RLM_TOKEN" /bin/bash -s <<'REMOTE_EOF'
set -e
USERNAME=$(whoami)
REMOTE_SCRIPT_PATH="/tmp/deploy-monitoring/deploy_monitoring_script.sh"
if [ ! -f "$REMOTE_SCRIPT_PATH" ]; then
    echo "[ERROR] Скрипт $REMOTE_SCRIPT_PATH не найден" && exit 1
fi
chmod +x "$REMOTE_SCRIPT_PATH"
echo "[INFO] sha256sum $REMOTE_SCRIPT_PATH:"
sha256sum "$REMOTE_SCRIPT_PATH" || echo "[WARNING] Не удалось вычислить sha256sum"
echo "[INFO] Нормализация перевода строк (CRLF -> LF)..."
if command -v dos2unix >/dev/null 2>&1; then
    dos2unix "$REMOTE_SCRIPT_PATH" || true
else
    sed -i 's/\r$//' "$REMOTE_SCRIPT_PATH" || true
fi
# Извлекаем значения из переданного JSON (если есть)
RPM_GRAFANA=$(jq -r '.rpm_url.grafana // empty' /tmp/temp_data_cred.json 2>/dev/null || echo "")
RPM_PROMETHEUS=$(jq -r '.rpm_url.prometheus // empty' /tmp/temp_data_cred.json 2>/dev/null || echo "")
RPM_HARVEST=$(jq -r '.rpm_url.harvest // empty' /tmp/temp_data_cred.json 2>/dev/null || echo "")

echo "[INFO] Проверка passwordless sudo..."
if ! sudo -n true 2>/dev/null; then
    echo "[ERROR] Требуется passwordless sudo (NOPASSWD) для пользователя $USERNAME" && exit 1
fi

echo "[INFO] Запуск скрипта с правами sudo..."
sudo -n env \
  SEC_MAN_ADDR="__SEC_MAN_ADDR__" \
  NAMESPACE_CI="__NAMESPACE_CI__" \
  RLM_API_URL="__RLM_API_URL__" \
  RLM_TOKEN="$RLM_TOKEN" \
  NETAPP_API_ADDR="__NETAPP_API_ADDR__" \
  GRAFANA_PORT="__GRAFANA_PORT__" \
  PROMETHEUS_PORT="__PROMETHEUS_PORT__" \
  VAULT_AGENT_KV="__VAULT_AGENT_KV__" \
  RPM_URL_KV="__RPM_URL_KV__" \
  NETAPP_SSH_KV="__NETAPP_SSH_KV__" \
  GRAFANA_WEB_KV="__GRAFANA_WEB_KV__" \
  SBERCA_CERT_KV="__SBERCA_CERT_KV__" \
  ADMIN_EMAIL="__ADMIN_EMAIL__" \
  SKIP_VAULT_INSTALL="__SKIP_VAULT_INSTALL__" \
  SKIP_RPM_INSTALL="__SKIP_RPM_INSTALL__" \
  GRAFANA_URL="$RPM_GRAFANA" \
  PROMETHEUS_URL="$RPM_PROMETHEUS" \
  HARVEST_URL="$RPM_HARVEST" \
  /bin/bash "$REMOTE_SCRIPT_PATH"
REMOTE_EOF
'''
                        def finalScript = scriptTpl
                            .replace('__SERVER_ADDRESS__',     params.SERVER_ADDRESS     ?: '')
                            .replace('__SEC_MAN_ADDR__',       params.SEC_MAN_ADDR       ?: '')
                            .replace('__NAMESPACE_CI__',       params.NAMESPACE_CI       ?: '')
                            .replace('__RLM_API_URL__',        params.RLM_API_URL        ?: '')
                            .replace('__NETAPP_API_ADDR__',    params.NETAPP_API_ADDR    ?: '')
                            .replace('__GRAFANA_PORT__',       params.GRAFANA_PORT       ?: '3000')
                            .replace('__PROMETHEUS_PORT__',    params.PROMETHEUS_PORT    ?: '9090')
                            .replace('__VAULT_AGENT_KV__',     params.VAULT_AGENT_KV     ?: '')
                            .replace('__RPM_URL_KV__',         params.RPM_URL_KV         ?: '')
                            .replace('__NETAPP_SSH_KV__',      params.NETAPP_SSH_KV      ?: '')
                            .replace('__GRAFANA_WEB_KV__',     params.GRAFANA_WEB_KV     ?: '')
                            .replace('__SBERCA_CERT_KV__',     params.SBERCA_CERT_KV     ?: '')
                            .replace('__ADMIN_EMAIL__',        params.ADMIN_EMAIL        ?: '')
                            .replace('__SKIP_VAULT_INSTALL__', params.SKIP_VAULT_INSTALL ? 'true' : 'false')
                            .replace('__SKIP_RPM_INSTALL__',   params.SKIP_RPM_INSTALL ? 'true' : 'false')
                        writeFile file: 'deploy_script.sh', text: finalScript
                        sh 'chmod +x deploy_script.sh'
                        withEnv(['SSH_KEY=' + env.SSH_KEY, 'SSH_USER=' + env.SSH_USER]) {
                            sh './deploy_script.sh'
                        }
                        sh 'rm -f deploy_script.sh'
                    }
                }
            }
        }

        stage('CDL: Проверка результатов') {
            agent { label "masterLin&&sbel8&&!static" }
            when {
                expression { params.SKIP_DEPLOYMENT != true }
            }
            steps {
                script {
                    echo "[STEP] Проверка результатов развертывания..."
                    withCredentials([sshUserPrivateKey(credentialsId: params.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                        writeFile file: 'check_results.sh', text: '''#!/bin/bash
ssh -i "$SSH_KEY" -q -o StrictHostKeyChecking=no \
    "$SSH_USER"@''' + params.SERVER_ADDRESS + ''' << 'ENDSSH'
echo "================================================"
echo "ПРОВЕРКА СЕРВИСОВ:"
echo "================================================"
systemctl is-active prometheus && echo "[OK] Prometheus активен" || echo "[FAIL] Prometheus не активен"
systemctl is-active grafana-server && echo "[OK] Grafana активен" || echo "[FAIL] Grafana не активен"
echo ""
echo "================================================"
echo "ПРОВЕРКА ПОРТОВ:"
echo "================================================"
ss -tln | grep -q ":''' + (params.PROMETHEUS_PORT ?: '9090') + ''' " && echo "[OK] Порт ''' + (params.PROMETHEUS_PORT ?: '9090') + ''' (Prometheus) открыт" || echo "[FAIL] Порт ''' + (params.PROMETHEUS_PORT ?: '9090') + ''' не открыт"
ss -tln | grep -q ":''' + (params.GRAFANA_PORT ?: '3000') + ''' " && echo "[OK] Порт ''' + (params.GRAFANA_PORT ?: '3000') + ''' (Grafana) открыт" || echo "[FAIL] Порт ''' + (params.GRAFANA_PORT ?: '3000') + ''' не открыт"
ss -tln | grep -q ":12990 " && echo "[OK] Порт 12990 (Harvest-NetApp) открыт" || echo "[FAIL] Порт 12990 не открыт"
ss -tln | grep -q ":12991 " && echo "[OK] Порт 12991 (Harvest-Unix) открыт" || echo "[FAIL] Порт 12991 не открыт"
exit 0
ENDSSH
'''
                        sh 'chmod +x check_results.sh'
                        def result
                        withEnv(['SSH_KEY=' + env.SSH_KEY, 'SSH_USER=' + env.SSH_USER]) {
                            result = sh(script: './check_results.sh', returnStdout: true).trim()
                        }
                        sh 'rm -f check_results.sh'
                        echo result
                    }
                }
            }
        }

        stage('CDL: Очистка') {
            agent { label "masterLin&&sbel8&&!static" }
            when {
                expression { params.SKIP_DEPLOYMENT != true }
            }
            steps {
                script {
                    echo "[STEP] Очистка временных файлов..."
                    sh "rm -rf temp_data_cred.json"
                    withCredentials([sshUserPrivateKey(credentialsId: params.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                        writeFile file: 'cleanup_script.sh', text: '''#!/bin/bash
ssh -i "$SSH_KEY" -q -o StrictHostKeyChecking=no \
    "$SSH_USER"@''' + params.SERVER_ADDRESS + ''' \
    "rm -rf /tmp/deploy-monitoring /tmp/monitoring_deployment.sh /tmp/temp_data_cred.json /opt/mon_distrib/mon_rpm_''' + env.DATE_INSTALL + '''/*.rpm" || true
'''
                        sh 'chmod +x cleanup_script.sh'
                        withEnv(['SSH_KEY=' + env.SSH_KEY, 'SSH_USER=' + env.SSH_USER]) {
                            sh './cleanup_script.sh'
                        }
                        sh 'rm -f cleanup_script.sh'
                    }
                    echo "[SUCCESS] Очистка завершена"
                }
            }
        }

        stage('CDL: Получение сведений о развертывании системы') {
            agent { label "masterLin&&sbel8&&!static" }
            when {
                expression { params.SKIP_DEPLOYMENT != true }
            }
            steps {
                script {
                    def domainName = ''
                    withCredentials([sshUserPrivateKey(credentialsId: params.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                        writeFile file: 'get_domain.sh', text: '''#!/bin/bash
ssh -i "$SSH_KEY" -q -o StrictHostKeyChecking=no \
    "$SSH_USER"@''' + params.SERVER_ADDRESS + ''' \
    "nslookup ''' + params.SERVER_ADDRESS + ''' 2>/dev/null | grep 'name =' | awk '{print \\$4}' | sed 's/\\.$//' || echo ''"
'''
                        sh 'chmod +x get_domain.sh'
                        withEnv(['SSH_KEY=' + env.SSH_KEY, 'SSH_USER=' + env.SSH_USER]) {
                            domainName = sh(script: './get_domain.sh', returnStdout: true).trim()
                        }
                        sh 'rm -f get_domain.sh'
                    }
                    if (domainName == '') {
                        domainName = params.SERVER_ADDRESS
                    }
                    def serverIp = ''
                    withCredentials([sshUserPrivateKey(credentialsId: params.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                        writeFile file: 'get_ip.sh', text: '''#!/bin/bash
ssh -i "$SSH_KEY" -q -o StrictHostKeyChecking=no \
    "$SSH_USER"@''' + params.SERVER_ADDRESS + ''' \
    "hostname -I | awk '{print \\$1}' || echo ''' + (params.SERVER_ADDRESS ?: '') + '''"
'''
                        sh 'chmod +x get_ip.sh'
                        withEnv(['SSH_KEY=' + env.SSH_KEY, 'SSH_USER=' + env.SSH_USER]) {
                            serverIp = sh(script: './get_ip.sh', returnStdout: true).trim()
                        }
                        sh 'rm -f get_ip.sh'
                    }
                    echo "================================================"
                    echo "[SUCCESS] Развертывание мониторинговой системы завершено!"
                    echo "================================================"
                    echo "[INFO] Доступ к сервисам:"
                    echo " • Prometheus: https://${serverIp}:${params.PROMETHEUS_PORT}"
                    echo " • Prometheus: https://${domainName}:${params.PROMETHEUS_PORT}"
                    echo " • Grafana: https://${serverIp}:${params.GRAFANA_PORT}"
                    echo " • Grafana: https://${domainName}:${params.GRAFANA_PORT}"
                    echo "[INFO] Информация о сервере:"
                    echo " • IP адрес: ${serverIp}"
                    echo " • Домен: ${domainName}"
                    echo "================================================"
                }
            }
        }
    }

    post {
        success {
            echo "================================================"
            echo "✅ Pipeline успешно завершен!"
            echo "================================================"
        }
        failure {
            echo "================================================"
            echo "❌ Pipeline завершился с ошибкой!"
            echo "Проверьте логи для диагностики проблемы"
            echo "================================================"
        }
        always {
            echo "Время выполнения: ${currentBuild.durationString}"
        }
    }
}
