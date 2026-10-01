# XVPN GCP Shell

**XVPN by shinusterben**

Deploy and manage the XVPN Docker image on **Google Cloud Run** directly from Google Cloud Shell or Google Cloud Skills Boost.

Docker image:

```text
docker.io/noahclanman/gcp:latest
```

Main XVPN source:

```text
https://github.com/noahclanman/gcp
```

Cloud Shell installer:

```text
https://github.com/noahclanman/gcp-shell
```

---

# Quick Install

Open **Google Cloud Shell** and run:

```bash
curl -fsSL https://raw.githubusercontent.com/noahclanman/gcp-shell/main/install.sh | bash
```

The installer asks for:

```text
Cloud Run service name
Cloud Run region
```

Example:

```text
Cloud Run service name [xvpn]: xvpn
Cloud Run region [us-central1]: us-central1
```

The installer deploys:

```text
docker.io/noahclanman/gcp:latest
```

to Google Cloud Run.

---

# Deployment Flow

```text
Google Cloud Console
        ↓
Google Cloud Shell
        ↓
gcp-shell/install.sh
        ↓
docker.io/noahclanman/gcp:latest
        ↓
Google Cloud Run
        ↓
https://SERVICE.run.app
```

---

# Default Cloud Run Settings

```text
Image:               docker.io/noahclanman/gcp:latest
Container Port:      8080
Memory:              512Mi
CPU:                 1
Concurrency:         500
Max Instances:       16
Timeout:             3600 seconds
Execution Env:       Second Generation
HTTP/2:              Enabled
CPU Boost:           Enabled
Public Access:       Enabled
```

No XVPN environment variables are required for the default deployment.

---

# Default XVPN User

```text
ID:    shinusterben
Alias: shinu
```

---

# Website

After deployment, Google Cloud Run gives you a URL similar to:

```text
https://xvpn-xxxxxxxxxx-uc.a.run.app
```

Main page:

```text
https://YOUR-CLOUD-RUN-URL/
```

The homepage displays:

```text
XVPN
by shinusterben
```

---

# XVPN Profile Page

```text
https://YOUR-CLOUD-RUN-URL/xvpn/shinu
```

Example:

```text
https://xvpn-xxxxxxxxxx-uc.a.run.app/xvpn/shinu
```

---

# Subscription

Default subscription:

```text
https://YOUR-CLOUD-RUN-URL/sub/shinu
```

Example:

```text
https://xvpn-xxxxxxxxxx-uc.a.run.app/sub/shinu
```

The old:

```text
/sub/shinu/plain
```

endpoint is not used.

---

# Default Protocols

XVPN includes:

```text
VLESS + XHTTP
VLESS + WebSocket
VLESS + gRPC
Trojan + WebSocket
VMess + WebSocket
Shadowsocks + WebSocket
```

---

# Inbound Paths

## VLESS + XHTTP

```text
/vless/xhttp/shinu
```

## VLESS + WebSocket

```text
/vless/ws/shinu
```

## VLESS + gRPC

```text
serviceName: vless/grpc/shinu
```

## Trojan + WebSocket

```text
/trojan/ws/shinu
```

## VMess + WebSocket

```text
/vmess/ws/shinu
```

## Shadowsocks + WebSocket

```text
/shadowsocks/ws/shinu
```

---

# XVPN Shell Dashboard

After installation, run:

```bash
xvpn
```

Example:

```text
========================================================================
                         XVPN CLOUD RUN
                           by shinusterben
========================================================================

Status:                ONLINE
Project:               qwiklabs-gcp-xxxxxxxx
Region:                us-central1
Service:               xvpn
Revision:              xvpn-00001-abc

========================================================================
                           CONTAINER
========================================================================

Image:                 docker.io/noahclanman/gcp:latest
Port:                  8080
Memory:                512Mi
CPU:                   1

========================================================================
                           CLOUD RUN
========================================================================

Concurrency:           500
Max Instances:         16
Timeout:               3600s
Execution Env:         Second Generation
HTTP/2:                Enabled
CPU Boost:             Enabled
Public Access:         Enabled

========================================================================
                           PROTOCOLS
========================================================================

VLESS + XHTTP           ON
VLESS + WebSocket       ON
VLESS + gRPC            ON
Trojan + WebSocket      ON
VMess + WebSocket       ON
Shadowsocks + WebSocket ON

========================================================================
                            ACCESS
========================================================================

Site:
https://xvpn-xxxxxxxxxx-uc.a.run.app/

XVPN Page:
https://xvpn-xxxxxxxxxx-uc.a.run.app/xvpn/shinu

Subscription:
https://xvpn-xxxxxxxxxx-uc.a.run.app/sub/shinu
```

---

# XVPN Menu

Run:

```bash
xvpn
```

Menu:

```text
[1] Refresh dashboard
[2] Show XVPN links / inbounds
[3] Show Cloud Run logs
[4] Redeploy latest Docker image
[5] Change service name
[6] Change region
[7] Delete Cloud Run service
[0] Exit
```

---

# XVPN Commands

Dashboard:

```bash
xvpn status
```

Show links:

```bash
xvpn links
```

Show logs:

```bash
xvpn logs
```

Redeploy latest Docker image:

```bash
xvpn update
```

Open menu:

```bash
xvpn
```

---

# Docker Hub

The XVPN Docker image is:

```text
docker.io/noahclanman/gcp:latest
```

The Cloud Shell installer deploys this image directly to Google Cloud Run.

---

# Manual Cloud Run Deployment

You can deploy XVPN manually without using the installer.

```bash
gcloud run deploy xvpn \
  --image docker.io/noahclanman/gcp:latest \
  --region us-central1 \
  --platform managed \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --concurrency 500 \
  --max-instances 16 \
  --timeout 3600 \
  --execution-environment gen2 \
  --cpu-boost \
  --use-http2 \
  --allow-unauthenticated
```

---

# Get Cloud Run URL

```bash
gcloud run services describe xvpn \
  --region us-central1 \
  --format='value(status.url)'
```

Example:

```text
https://xvpn-xxxxxxxxxx-uc.a.run.app
```

---

# Access URLs

Website:

```text
https://YOUR-CLOUD-RUN-URL/
```

XVPN page:

```text
https://YOUR-CLOUD-RUN-URL/xvpn/shinu
```

Subscription:

```text
https://YOUR-CLOUD-RUN-URL/sub/shinu
```

---

# Deploy from Google Cloud Console

You can also deploy XVPN without Cloud Shell.

Open:

```text
Google Cloud Console
→ Cloud Run
→ Deploy Container
```

Use:

```text
docker.io/noahclanman/gcp:latest
```

Container port:

```text
8080
```

Suggested configuration:

```text
Memory:               512Mi
CPU:                  1
Concurrency:          500
Max Instances:        16
Timeout:              3600 seconds
Execution Env:        Second Generation
HTTP/2:               Enabled
CPU Boost:            Enabled
Public Access:        Enabled
```

No environment variables are required.

---

# Google Cloud Skills Boost

XVPN can also be deployed from a Google Cloud Skills Boost / Qwiklabs project.

Open Cloud Shell and run:

```bash
curl -fsSL https://raw.githubusercontent.com/noahclanman/gcp-shell/main/install.sh | bash
```

The installer automatically uses the currently selected Google Cloud project.

---

# Check Current Project

```bash
gcloud config get-value project
```

---

# List Cloud Run Services

```bash
gcloud run services list
```

---

# Check XVPN Service

```bash
gcloud run services describe xvpn \
  --region us-central1
```

---

# View Logs

Using the XVPN manager:

```bash
xvpn logs
```

Or manually:

```bash
gcloud run services logs read xvpn \
  --region us-central1 \
  --limit 100
```

---

# Update XVPN

Use:

```bash
xvpn update
```

This redeploys:

```text
docker.io/noahclanman/gcp:latest
```

You can also manually redeploy:

```bash
gcloud run deploy xvpn \
  --image docker.io/noahclanman/gcp:latest \
  --region us-central1
```

---

# Delete XVPN

Open:

```bash
xvpn
```

and choose:

```text
[7] Delete Cloud Run service
```

Or manually:

```bash
gcloud run services delete xvpn \
  --region us-central1
```

---

# Custom User

The default XVPN account is:

```text
shinusterben:shinu
```

You can optionally override it.

Example:

```bash
gcloud run deploy xvpn \
  --image docker.io/noahclanman/gcp:latest \
  --region us-central1 \
  --set-env-vars USERS="noah:noah" \
  --allow-unauthenticated
```

Then:

```text
/xvpn/noah
/sub/noah
```

---

# Multiple Users

Example:

```text
USERS=shinusterben:shinu,noah:noah,user3:user3
```

Pages:

```text
/xvpn/shinu
/xvpn/noah
/xvpn/user3
```

Subscriptions:

```text
/sub/shinu
/sub/noah
/sub/user3
```

---

# Optional Environment Variables

No variables are required for the default configuration.

Optional variables:

```text
USERS
ENABLE_VMESS
ENABLE_GRPC
ENABLE_SHADOWSOCKS
MAX_DEVICES
DEVICE_WINDOW
DEVICE_INTERVAL
TROJAN_PASSWORD
SHOW_LINKS
```

---

# Cloud Run Port

XVPN listens internally on:

```text
8080
```

You do not add `:8080` to your public Cloud Run URL.

Correct:

```text
https://YOUR-SERVICE.run.app/sub/shinu
```

Not:

```text
https://YOUR-SERVICE.run.app:8080/sub/shinu
```

Cloud Run handles the public HTTPS connection.

---

# HTTP Port 80

Google Cloud Run provides an HTTPS endpoint and redirects HTTP requests to HTTPS.

A normal public raw non-TLS port `80` transport is therefore not exposed directly by Cloud Run.

---

# Quick Reference

Install:

```bash
curl -fsSL https://raw.githubusercontent.com/noahclanman/gcp-shell/main/install.sh | bash
```

Dashboard:

```bash
xvpn
```

Status:

```bash
xvpn status
```

Links:

```bash
xvpn links
```

Logs:

```bash
xvpn logs
```

Update:

```bash
xvpn update
```

Docker image:

```text
docker.io/noahclanman/gcp:latest
```

Website:

```text
https://YOUR-CLOUD-RUN-URL/
```

XVPN page:

```text
https://YOUR-CLOUD-RUN-URL/xvpn/shinu
```

Subscription:

```text
https://YOUR-CLOUD-RUN-URL/sub/shinu
```

---

# XVPN

```text
XVPN
by shinusterben
```
