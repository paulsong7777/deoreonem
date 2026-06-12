# DeoReoNem — Oracle Cloud Test Deployment

**Version:** 0.3
**Last Updated:** 2026-06-12
**Purpose:** Friend testing only. Not production.

---

## Architecture

```
Friend's Windows PC                    Oracle Cloud Server
┌──────────────────┐                  ┌─────────────────────────────────┐
│ deoreonem_desktop │                  │  Nginx Proxy Manager (443/80)   │
│ (.exe)            │                  │         ↓                       │
│                   │── HTTPS ───────→ │  deoreonem-api (port 8080)      │
└──────────────────┘                  │         ↓                       │
                                      │  PostgreSQL 15 (internal only)  │
                                      └─────────────────────────────────┘

Domain: https://deoreonem-api.scope-works.net
```

---

## Prerequisites

- Oracle Cloud Ubuntu server with Docker and Docker Compose installed
- Nginx Proxy Manager already running on the server
- DNS A record: `deoreonem-api.scope-works.net` → Oracle server public IP
- SSL certificate via Nginx Proxy Manager (Let's Encrypt)

---

## Server Directory Structure

```
~/deoreonem/
├── docker-compose.yml    ← from deploy/oracle-test/
├── .env                  ← from .env.example (filled in)
└── deoreonem-api.jar     ← built JAR (or use Docker image)
```

---

## Deployment Steps

### 1. Build the backend JAR (on dev machine)

```bash
cd server/deoreonem_api
./gradlew.bat bootJar
# Output: build/libs/deoreonem-api-0.1.0.jar
```

### 2. Build Docker image (on dev machine or server)

```bash
cd server/deoreonem_api
docker build -t deoreonem-api:latest .
```

Or transfer the JAR to the server and build there:
```bash
scp build/libs/deoreonem-api-0.1.0.jar user@oracle-server:~/deoreonem/
scp Dockerfile user@oracle-server:~/deoreonem/
# Then on server: docker build -t deoreonem-api:latest .
```

### 3. Copy deployment files to server

```bash
scp deploy/oracle-test/docker-compose.yml user@oracle-server:~/deoreonem/
scp deploy/oracle-test/.env.example user@oracle-server:~/deoreonem/.env
```

### 4. Configure .env on server

```bash
ssh user@oracle-server
cd ~/deoreonem
nano .env
# Fill in a strong POSTGRES_PASSWORD
```

### 5. Start services

```bash
cd ~/deoreonem
docker compose up -d
```

### 6. Verify health

```bash
curl http://localhost:8080/api/v1/health
# Expected: {"status":"UP","service":"deoreonem-api","version":"0.1.0"}
```

### 7. Configure Nginx Proxy Manager

1. Add Proxy Host:
   - Domain: `deoreonem-api.scope-works.net`
   - Scheme: `http`
   - Forward Hostname / IP: `localhost` (or `host.docker.internal` or the server's internal IP)
   - Forward Port: `8080`
2. SSL tab:
   - Request new SSL certificate (Let's Encrypt)
   - Force SSL: enabled

### 8. Verify remote access

```bash
curl https://deoreonem-api.scope-works.net/api/v1/health
# Expected: {"status":"UP","service":"deoreonem-api","version":"0.1.0"}
```

---

## Building Tester ZIP (pointing to remote API)

On the developer machine:

```bash
cd apps/deoreonem_desktop
flutter build windows --release --dart-define=API_BASE_URL=https://deoreonem-api.scope-works.net/api/v1
```

ZIP the release folder:
```powershell
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "deoreonem-windows-tester.zip"
```

Send the ZIP to friend testers.

---

## Operational Commands

```bash
# View logs
docker compose logs -f deoreonem-api

# Restart API
docker compose restart deoreonem-api

# Stop everything
docker compose down

# Stop and remove data (DESTRUCTIVE)
docker compose down -v

# Rebuild and restart after code changes
docker compose build deoreonem-api
docker compose up -d deoreonem-api
```

---

## CORS Note

The Flutter Windows desktop app makes HTTP requests via Dio (not a browser). CORS headers are not enforced by Dio — they are a browser-only security mechanism. The existing `CorsConfig.java` allows `http://localhost*` which is sufficient for local development. For the remote deployment, no CORS change is needed because the Windows .exe is not subject to browser CORS policy.

---

## Security Warnings

⚠️ **No authentication in MVP 0.3**
- Anyone who knows the API URL can create sessions and read data
- Do NOT enter real company, customer, or private information
- Use test sentences only during friend testing
- PostgreSQL is not exposed publicly (Docker internal network only)
- Consider adding Spring Security (Phase 5) before any broader distribution

---

## DNS Record

| Type | Name | Value | TTL |
|---|---|---|---|
| A | deoreonem-api.scope-works.net | [Oracle server public IP] | 300 |

---

## Rollback

To completely remove the deployment:

```bash
cd ~/deoreonem
docker compose down -v
rm -rf ~/deoreonem
```

Remove the Nginx Proxy Manager proxy host and DNS record.
