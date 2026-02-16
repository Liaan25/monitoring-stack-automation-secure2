# 📦 Информация о проекте

## Название проекта

**monitoring-stack-automation**

*Система автоматизированного развертывания стека мониторинга*

---

## 🎯 Обоснование названия

### Почему `monitoring-stack-automation`?

| Критерий | Обоснование |
|----------|-------------|
| **Описательность** | ✅ Сразу понятно: автоматизация стека мониторинга |
| **Краткость** | ✅ 3 слова, 28 символов - оптимальная длина |
| **Профессионализм** | ✅ Используется в enterprise проектах |
| **Уникальность** | ✅ Не конфликтует с другими проектами |
| **Стандарт** | ✅ Дефисы между словами (kebab-case) |
| **SEO/Searchability** | ✅ Легко найти и индексировать |

### Альтернативные варианты (отклонены)

| Название | Почему отклонено |
|----------|------------------|
| `monitoring-deployment` | ❌ Слишком общее |
| `harvest-prometheus-grafana` | ❌ Длинное, привязано к конкретным технологиям |
| `automated-monitoring` | ❌ Не отражает "stack" (набор компонентов) |
| `monitoring-installer` | ❌ Не отражает автоматизацию через CI/CD |
| `sber-monitoring-automation` | ❌ Привязка к конкретной компании |

---

## 📋 Соответствие стандартам

### ✅ GitHub/GitLab Naming Conventions
```
✅ kebab-case (дефисы)
✅ Строчные буквы
✅ Описательное имя
✅ Без специальных символов
```

### ✅ Enterprise Project Standards
```
✅ Начинается с домена (monitoring)
✅ Содержит тип проекта (automation)
✅ Отражает архитектуру (stack)
✅ Профессиональное звучание
```

### ✅ SEO & Documentation
```
✅ Ключевые слова: monitoring, stack, automation
✅ Легко запомнить
✅ Легко произнести
✅ Легко написать
```

---

## 🏗️ Компоненты стека

### Что входит в "stack":

1. **NetApp Harvest** - сборщик метрик
2. **Prometheus** - база данных временных рядов
3. **Grafana** - визуализация и дашборды
4. **Vault Agent** - управление секретами

### Что включает "automation":

1. **Jenkins CI/CD** - автоматический деплой
2. **Ansible-подобная** конфигурация
3. **Идемпотентность** - можно запускать многократно
4. **Self-healing** - автоматическое восстановление
5. **Zero-touch** - без ручного вмешательства

---

## 📊 Структура проекта

```
monitoring-stack-automation/
├── 📖 README.md                          # Полная документация
├── 📦 PROJECT_INFO.md                    # Этот файл (мета-информация)
├── 🔒 SECURITY.md                        # Политика безопасности
├── 📝 RENAME_GUIDE.md                    # История переименований
├── 🔄 Jenkinsfile                        # CI/CD pipeline
├── 🚀 install-monitoring-stack.sh        # Основной скрипт установки
├── ⚙️  sudoers.example                    # Пример sudo конфигурации
├── 📋 sudoers.template                   # Шаблон sudo конфигурации
└── 🛡️ wrappers/                          # Security wrappers
    ├── build-integrity-checkers.sh       # SHA256 integrity checks
    ├── config-writer.sh                  # Safe config writer
    ├── firewall-manager.sh               # iptables management
    ├── grafana-api-wrapper.sh            # Grafana API wrapper
    └── rlm-api-wrapper.sh                # RLM API wrapper
```

---

## 🎨 Брендинг и стиль

### Логотип проекта (ASCII)

```
╔═══════════════════════════════════════════════════╗
║                                                   ║
║   ███╗   ███╗ ██████╗ ███╗   ██╗██╗████████╗    ║
║   ████╗ ████║██╔═══██╗████╗  ██║██║╚══██╔══╝    ║
║   ██╔████╔██║██║   ██║██╔██╗ ██║██║   ██║       ║
║   ██║╚██╔╝██║██║   ██║██║╚██╗██║██║   ██║       ║
║   ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║   ██║       ║
║   ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚═╝       ║
║                                                   ║
║        STACK AUTOMATION                          ║
║   Harvest • Prometheus • Grafana                 ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
```

### Цветовая схема (для документации)

```
Основные цвета:
  🔵 Синий #0066CC    - Automation, CI/CD
  🟢 Зеленый #00AA44  - Success, Monitoring
  🟡 Желтый #FFAA00   - Warning, Alert
  🔴 Красный #CC0000  - Error, Critical
  ⚫ Серый #666666    - Infrastructure
```

---

## 🌐 Использование в различных контекстах

### Git Repository
```bash
git clone https://github.com/organization/monitoring-stack-automation.git
```

### Docker Image (если будет)
```bash
docker pull registry.company.com/monitoring-stack-automation:latest
```

### Jenkins Job
```
Jenkins → New Item → "monitoring-stack-automation"
```

### Confluence/Wiki
```
Title: Monitoring Stack Automation
Space: DevOps Automation
Label: monitoring, automation, stack
```

### Jira Project
```
Project Key: MSA
Project Name: Monitoring Stack Automation
```

---

## 📈 Версионирование

### Текущая версия

**v3.0.0** (2026-01-23)

### Semantic Versioning

Проект следует [Semantic Versioning 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH

3.0.0
│ │ │
│ │ └─── PATCH: bug fixes, документация
│ └───── MINOR: новые фичи (обратная совместимость)
└─────── MAJOR: breaking changes
```

### История версий

| Версия | Дата | Описание |
|--------|------|----------|
| v3.0.0 | 2026-01-23 | 🎨 Professional Naming & Final Polish |
| v2.8.0 | 2026-01-20 | 🔧 Bug Fixes & Stability (Grafana HTTP 400) |
| v2.7.0 | 2026-01-15 | 🔒 Enhanced Security & Monitoring (mTLS, Harvest) |
| v2.6.0 | 2026-01-08 | 👥 User Units & KAE Model |
| v2.5.0 | 2025-12-20 | 🔐 SHA256 Integrity Checks |
| v2.4.0 | 2025-12-10 | 🌐 Network & Certificate Management |
| v2.3.0 | 2025-12-01 | 🔄 RLM Integration & Task Management |
| v2.2.0 | 2025-11-20 | 🔥 Firewall & Network Security |
| v2.1.0 | 2025-11-10 | 🎨 Grafana API Integration |
| v2.0.0 | 2025-11-01 | 🚀 Jenkins CI/CD Integration |
| v1.5.0 | 2025-10-25 | 🛡️ Security Wrappers Framework |
| v1.4.0 | 2025-10-20 | 📊 Prometheus & Grafana Configuration |
| v1.3.0 | 2025-10-18 | 🔐 Vault Agent Configuration |
| v1.2.0 | 2025-10-16 | 🧹 Cleanup & Prerequisites |
| v1.1.0 | 2025-10-15 | 📝 Initial Script Structure |
| v1.0.0 | 2025-10-14 | 🎉 Project Inception |

---

## 🏷️ Теги и метаданные

### Keywords
```
monitoring, automation, prometheus, grafana, harvest, 
netapp, jenkins, ci-cd, devops, infrastructure-as-code,
vault, security, enterprise, sberbank
```

### Topics (GitHub)
```
monitoring-automation
devops-tools
infrastructure-automation
prometheus
grafana
netapp-harvest
jenkins-pipeline
vault-integration
enterprise-monitoring
```

### Classifications
```
Type:         Automation Tool
Category:     Monitoring & Observability
Domain:       DevOps / SRE
Language:     Bash, Groovy (Jenkinsfile)
Platform:     Linux (RHEL 8+)
License:      Internal/Proprietary
Audience:     Enterprise IT
Maturity:     Production-Ready
```

---

## 📚 Связанные проекты

### Upstream Dependencies
- [HashiCorp Vault](https://www.vaultproject.io/) - Secret Management
- [Jenkins](https://www.jenkins.io/) - CI/CD
- [NetApp Harvest](https://github.com/NetApp/harvest) - Metrics Collector
- [Prometheus](https://prometheus.io/) - Time Series DB
- [Grafana](https://grafana.com/) - Visualization

### Similar Projects
- `monitoring-deployment-toolkit` - другой подход к деплою
- `observability-automation` - более широкий scope
- `infrastructure-monitoring` - focus на инфраструктуре

### Related Documentation
- RLM API Documentation
- SberInfra Monitoring Standards
- Security Policy (SECURITY.md)

---

## 👥 Ownership

### Maintainers
- DevOps Team
- Monitoring Team
- Infrastructure Team

### Stakeholders
- Security Team (ИБ)
- System Administrators
- Development Teams
- SRE Team

### Support Channels
- 📧 Email: devops-team@company.com
- 💬 Slack: #monitoring-automation
- 🎫 Jira: MSA project
- 📚 Wiki: confluence/monitoring-stack-automation

---

## 🔗 Quick Links

- [📖 Full Documentation](README.md)
- [🔒 Security Policy](SECURITY.md)
- [📝 Rename Guide](RENAME_GUIDE.md)
- [🔄 Jenkinsfile](Jenkinsfile)
- [🚀 Main Script](install-monitoring-stack.sh)

---

## 💡 Философия проекта

### Принципы

1. **Automation First** - автоматизация превыше всего
2. **Security by Design** - безопасность на уровне архитектуры
3. **Simplicity** - простота использования
4. **Reliability** - надежность и идемпотентность
5. **Documentation** - качественная документация

### Цели

- ✅ Сократить время развертывания с 2 часов до 15 минут
- ✅ Устранить человеческие ошибки
- ✅ Обеспечить единообразие установок
- ✅ Соответствие требованиям ИБ
- ✅ Self-service для команд разработки

---

## 🎯 Roadmap

### v3.x (текущая ветка)
- ✅ Профессиональные названия
- ✅ Полная документация
- 🔄 Интеграция с GitLab CI
- 📋 Helm charts для Kubernetes

### v4.x (планируется)
- 🔮 Multi-cloud support (Azure, AWS)
- 🔮 Ansible playbooks
- 🔮 Terraform modules
- 🔮 Advanced monitoring (Loki, Tempo)

---

<div align="center">

**monitoring-stack-automation**

*Enterprise Monitoring Automation Suite*

---

Made with ❤️ by DevOps Team

[Documentation](README.md) • [Security](SECURITY.md) • [Support](#support-channels)

</div>
