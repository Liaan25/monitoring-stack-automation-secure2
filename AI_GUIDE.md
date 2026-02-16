# 🤖 AI Assistant Quick Guide

> **Purpose:** This file helps AI assistants quickly understand the project structure and start working effectively.

---

## 📋 Quick Overview

**Project Name:** Monitoring Stack Automation  
**Version:** 2.1.0  
**Type:** CI/CD automation for deploying Harvest → Prometheus → Grafana monitoring stack  
**Main Technologies:** Jenkins Pipeline, Bash, HashiCorp Vault, Security Wrappers  

---

## 🎯 Essential Files to Read First

### 1️⃣ **Start Here** (in order)
```
1. README.md              # Complete project documentation (1325 lines)
2. PROJECT_INFO.md        # Project meta-information and philosophy
3. SECURITY.md            # Security architecture and requirements
4. CHANGELOG.md           # Development history (2025-10-14 to present)
```

### 2️⃣ **Core Executable Files**
```
Jenkinsfile                           # CI/CD pipeline (10 stages)
install-monitoring-stack.sh           # Main deployment script (4025 lines, 45 functions)
wrappers/build-integrity-checkers.sh  # Generates security launchers
```

### 3️⃣ **Security Wrappers** (called by main script)
```
wrappers/config-writer.sh        # Whitelisted file operations (10 uses)
wrappers/firewall-manager.sh     # iptables management (1 use)
wrappers/grafana-api-wrapper.sh  # Grafana API + HTTP checks (13 uses)
wrappers/rlm-api-wrapper.sh      # RLM API interactions (8 uses)
```

---

## 🏗️ Project Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         JENKINS PIPELINE                         │
│  (Jenkinsfile: 10 stages, Vault integration, SCP transfer)     │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  │ generates & transfers
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│              TARGET SERVER: install-monitoring-stack.sh          │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Phase 1: Validation (4 functions)                         │  │
│  │  - Check root, OS, paths, packages                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Phase 2: Setup (8 functions)                              │  │
│  │  - Create users, directories, systemd units               │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Phase 3: Security (5 functions)                           │  │
│  │  - Setup sudoers, firewall, wrappers                      │  │
│  │  - Uses: config-writer, firewall-manager                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Phase 4: Harvest → Prometheus (10 functions)              │  │
│  │  - Configure Harvest, start services                      │  │
│  │  - Uses: config-writer                                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Phase 5: RLM Registration (4 functions)                   │  │
│  │  - Register with RLM API, wait for task completion        │  │
│  │  - Uses: rlm-api-wrapper                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Phase 6: Grafana Setup (8 functions)                      │  │
│  │  - Configure datasources, service accounts, tokens        │  │
│  │  - Uses: grafana-api-wrapper                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Phase 7: Finalization (6 functions)                       │  │
│  │  - Health checks, logging, cleanup                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Security System (Critical!)

### Three-Layer Protection Model

1. **Layer 1: Sudoers Configuration**
   - User `jenkins-deploy` can run only specific wrapper launchers
   - No direct root access to sensitive commands
   - Example: `sudoers.example`, `sudoers.template`

2. **Layer 2: Security Wrappers**
   - Bash scripts with path whitelisting and input validation
   - Each wrapper handles ONE security domain (firewall, files, APIs)
   - Located in `wrappers/` directory

3. **Layer 3: Integrity Checkers (SHA256)**
   - Generated by `build-integrity-checkers.sh` in Jenkins
   - Each launcher verifies its wrapper's SHA256 hash before execution
   - Prevents tampering and unauthorized modifications

### Wrapper Usage Pattern
```bash
# In install-monitoring-stack.sh:
sudo /usr/local/bin/config-writer.launcher write "/path/to/file" "content"
sudo /usr/local/bin/firewall-manager.launcher add-rule "8080" "tcp"
sudo /usr/local/bin/grafana-api-wrapper.launcher create-datasource "name" "url"
sudo /usr/local/bin/rlm-api-wrapper.launcher create-task "hostname" "192.168.1.10"
```

---

## 🔑 Secrets Management

### Sources
1. **HashiCorp Vault** (via `withVault` in Jenkins)
   - `SECRET_PROD/temp_data_cred.json` → `data_sec.json` (Prometheus credentials)
   - SSH credentials for SCP transfer

2. **Jenkins Credentials**
   - `vault-token-id` → `VAULT_TOKEN`
   - `dev-server-ssh-key` → `SSH_KEY`

3. **Environment Variables** (set in main script)
   - `RLM_TOKEN`: from `data_sec.json`
   - `GRAFANA_BEARER_TOKEN`: from `data_sec.json`

### Flow
```
Jenkins (Vault) → data_sec.json → SCP to target → Source in bash → Export to env
```

---

## 📂 Project Structure

```
monitoring-stack-automation/
├── Jenkinsfile                           # CI/CD pipeline entry point
├── install-monitoring-stack.sh           # Main deployment script
├── README.md                             # Full documentation
├── SECURITY.md                           # Security guidelines
├── PROJECT_INFO.md                       # Project meta-info
├── CHANGELOG.md                          # Development history
├── RENAME_GUIDE.md                       # File naming documentation
├── AI_GUIDE.md                           # This file
├── sudoers.example                       # Sudoers config (simple)
├── sudoers.template                      # Sudoers config (detailed)
└── wrappers/
    ├── build-integrity-checkers.sh       # Launcher generator
    ├── config-writer.sh                  # File operations wrapper
    ├── firewall-manager.sh               # iptables wrapper
    ├── grafana-api-wrapper.sh            # Grafana API wrapper
    └── rlm-api-wrapper.sh                # RLM API wrapper
```

---

## 🚀 Execution Flow

### Jenkins Pipeline (Jenkinsfile)
```
1. Checkout Code         → Clone from Git
2. Validate Code         → Shellcheck, syntax check, grep for secrets
3. Read Vault Secrets    → Fetch credentials
4. Generate Launchers    → build-integrity-checkers.sh creates SHA256 launchers
5. Prepare Transfer      → Stash files for deployment agent
6. SCP to Target         → Transfer all files to target server
7. Execute Deployment    → SSH to target, run install-monitoring-stack.sh
8. Verify Deployment     → Check services (Harvest, Prometheus, Grafana)
9. Cleanup               → Remove temporary files
10. Post Actions         → Logging, notifications
```

### Main Script (install-monitoring-stack.sh)
```
Phase 1: Pre-flight checks (root, OS, packages)
Phase 2: User and directory setup
Phase 3: Security hardening (sudoers, firewall, wrappers)
Phase 4: Harvest + Prometheus deployment
Phase 5: RLM registration (async task API)
Phase 6: Grafana configuration (datasources, tokens)
Phase 7: Health checks and finalization
```

---

## 🛠️ Common Task Scenarios

### Scenario 1: Modify Security Wrapper
**Files to check:**
1. `wrappers/<wrapper-name>.sh` (the wrapper itself)
2. `wrappers/build-integrity-checkers.sh` (launcher generation)
3. `sudoers.example` or `sudoers.template` (permissions)
4. `install-monitoring-stack.sh` (usage of wrapper)
5. `SECURITY.md` (documentation update)

**Important:** Any change to a wrapper requires regenerating launchers (automatic in Jenkins).

---

### Scenario 2: Add New Deployment Step
**Files to modify:**
1. `install-monitoring-stack.sh` (add function, call in main flow)
2. Possibly create new wrapper in `wrappers/` (if needs root/security)
3. Update `README.md` → "Server-Side Script Operation" section
4. Update `CHANGELOG.md` with new feature

**Pattern:** Follow existing function naming (`action_target_qualifier`)

---

### Scenario 3: Debugging Jenkins Pipeline
**Files to check:**
1. `Jenkinsfile` (all 10 stages)
2. Jenkins build logs (check stage failures)
3. `wrappers/build-integrity-checkers.sh` (if launcher generation fails)
4. Vault credentials (if `withVault` fails)

**Common issues:**
- SCP failures → check `SSH_KEY` credential
- Vault failures → check `VAULT_TOKEN` and secret paths
- Shellcheck failures → fix syntax in modified scripts

---

### Scenario 4: Understand Wrapper Usage
**Quick search:**
```bash
# In install-monitoring-stack.sh, search for:
grep -n "config-writer.launcher" install-monitoring-stack.sh      # 10 uses
grep -n "firewall-manager.launcher" install-monitoring-stack.sh   # 1 use
grep -n "grafana-api-wrapper.launcher" install-monitoring-stack.sh # 13 uses
grep -n "rlm-api-wrapper.launcher" install-monitoring-stack.sh    # 8 uses
```

**Each wrapper has modes:**
- `config-writer.sh`: `write`, `append`, `create-dir`, `remove`, `chown`, `chmod`
- `firewall-manager.sh`: `add-rule`, `remove-rule`, `list-rules`, `save-rules`
- `grafana-api-wrapper.sh`: `create-datasource`, `delete-datasource`, `create-sa`, `create-token`, `http-check`
- `rlm-api-wrapper.sh`: `create-task`, `get-status`, `delete-task`, `list-tasks`

---

## 📊 Key Statistics

- **Main Script:** 4025 lines, 45 functions
- **Jenkinsfile:** 10 stages, ~400 lines
- **Wrappers:** 5 files, ~1500 lines total
- **Documentation:** 6 markdown files, ~3000 lines total
- **Wrapper Usage:** 32 total calls in main script
- **Development Period:** 2025-10-14 to 2026-01-23 (current)
- **Version:** 2.1.0

---

## 🧪 Verification Points

### All Wrappers Are Used ✅
- `config-writer.sh` → 10 uses
- `firewall-manager.sh` → 1 use
- `grafana-api-wrapper.sh` → 13 uses
- `rlm-api-wrapper.sh` → 8 uses
- `build-integrity-checkers.sh` → 1 use (in Jenkinsfile)

### No Dead Code ✅
- All 45 functions in `install-monitoring-stack.sh` are called
- All environment variables are used
- No commented-out blocks
- No TODO/FIXME/DEPRECATED markers

### All Files Professionally Named ✅
- Kebab-case naming convention
- Descriptive English names
- Standard extensions (`.example`, `.template`)

---

## 💡 Important Concepts

### 1. **Integrity Checking**
Every wrapper has a corresponding launcher with embedded SHA256 hash. If wrapper is modified, hash verification fails → prevents execution.

### 2. **Sudoers Principle**
User `jenkins-deploy` never gets full root access. Only specific wrapper launchers are allowed via sudo.

### 3. **Async RLM Tasks**
RLM registration is asynchronous. Script creates task → polls status → waits for completion (with timeout).

### 4. **Grafana Bearer Tokens**
Two tokens: one from RLM (stored in `data_sec.json`), one created by script for Prometheus datasource.

### 5. **Systemd User Units**
Harvest runs as user `harvest` using systemd user units (not system units). Requires `loginctl enable-linger harvest`.

---

## 🎓 Learning Path for New AI

### Fast Track (5 minutes)
```
1. Read this file (AI_GUIDE.md)
2. Skim README.md → sections "Quick Start" and "Deployment Process"
3. Look at Jenkinsfile → understand 10 stages
4. Search install-monitoring-stack.sh for function names to understand flow
```

### Standard Track (15 minutes)
```
1. Read AI_GUIDE.md
2. Read README.md completely
3. Read SECURITY.md
4. Examine one wrapper (e.g., grafana-api-wrapper.sh)
5. Trace one complete flow (e.g., Grafana setup)
```

### Deep Dive (1 hour)
```
1. Read all documentation files
2. Read Jenkinsfile with all stages
3. Read install-monitoring-stack.sh with all 45 functions
4. Read all 5 wrappers
5. Understand sudoers configuration
6. Review CHANGELOG.md for historical context
```

---

## 🔍 Quick Reference Commands

### Check wrapper usage in main script
```bash
grep -E "(config-writer|firewall-manager|grafana-api-wrapper|rlm-api-wrapper)\.launcher" install-monitoring-stack.sh
```

### Find function definition
```bash
grep -n "^function_name()" install-monitoring-stack.sh
```

### Find function calls
```bash
grep -n "function_name" install-monitoring-stack.sh
```

### List all functions
```bash
grep -n "^[a-z_]*() {" install-monitoring-stack.sh
```

### Find environment variable usage
```bash
grep -n "\$VARIABLE_NAME" install-monitoring-stack.sh
```

---

## 🚨 Red Flags to Watch For

❌ **Never do this:**
- Bypass integrity checkers
- Remove wrapper usage without updating sudoers
- Hardcode secrets in scripts
- Skip SHA256 verification
- Grant full sudo access to `jenkins-deploy`

✅ **Always do this:**
- Test all changes in non-production first
- Update documentation when modifying logic
- Regenerate launchers after wrapper changes
- Validate JSON before API calls
- Check exit codes and log errors

---

## 📞 Additional Resources

- **Full Documentation:** `README.md` (comprehensive guide)
- **Security Details:** `SECURITY.md` (for InfoSec audits)
- **Renaming History:** `RENAME_GUIDE.md` (old vs new file names)
- **Project Philosophy:** `PROJECT_INFO.md` (design decisions)
- **Change History:** `CHANGELOG.md` (development timeline)

---

## 🎯 Quick Decision Tree

```
┌─ Need to understand project overview?
│  └─► Read README.md
│
┌─ Need to modify Jenkins pipeline?
│  └─► Read Jenkinsfile + README.md "Jenkins Configuration" section
│
┌─ Need to modify deployment logic?
│  └─► Read install-monitoring-stack.sh + find function
│
┌─ Need to modify security wrapper?
│  └─► Read SECURITY.md + specific wrapper + sudoers + launcher generation
│
┌─ Need to understand secret management?
│  └─► Read README.md "Security System" + SECURITY.md + Jenkinsfile withVault
│
┌─ Need to debug deployment failure?
│  └─► Check Jenkins logs → SSH to target → check systemd status
│
└─ Need historical context?
   └─► Read CHANGELOG.md + PROJECT_INFO.md
```

---

## 📌 TL;DR for Impatient AI

**What:** Jenkins deploys Harvest→Prometheus→Grafana monitoring stack  
**How:** Pipeline generates secure launchers → SCP to target → run main script  
**Security:** 3-layer model (sudoers + wrappers + integrity checks)  
**Files:** Jenkinsfile (pipeline) + install-monitoring-stack.sh (main) + 5 wrappers  
**Secrets:** Vault → data_sec.json → environment variables  
**Key Insight:** All sensitive operations go through security wrappers with SHA256 verification

**Start here:** README.md + this file = 90% understanding

---

*Last Updated: 2026-01-23*  
*Project Version: 2.1.0*  
*AI Guide Version: 1.0.0*
