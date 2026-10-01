# Umbra GCP Shell

Deploy and manage the Umbra Docker image on **Google Cloud Run** directly from:

- Google Cloud Shell
- Google Cloud Console
- Google Cloud Skills Boost / Qwiklabs Cloud Shell

Docker image:

```text
docker.io/noahclanman/gcp:latest
```

This project is designed for:

```text
Google Cloud Shell
        ↓
Run install.sh
        ↓
Deploy Docker image
        ↓
Google Cloud Run
        ↓
Get *.run.app URL
        ↓
Use /sub/shinu
```

---

## Quick Install

Open **Google Cloud Shell** and run:

```bash
curl -fsSL https://raw.githubusercontent.com/noahclanman/gcp-shell/main/install.sh | bash
```

The installer will ask for:

```text
Cloud Run service name
Cloud Run region
```

Example:

```text
Cloud Run service name [umbra]: erwan
Cloud Run region [us-central1]: us-central1
```

The installer then deploys:

```text
docker.io/noahclanman/gcp:latest
```

to Google Cloud Run.

---

# Default Cloud Run Configuration

The installer uses:

```text
Container image:      docker.io/noahclanman/gcp:latest
Container port:       8080
Memory:               512Mi
CPU:                  1
Concurrency:          500
Max instances:        16
Timeout:              3600 seconds
Execution environment: Second Generation
HTTP/2:               Enabled
CPU Boost:            Enabled
Public access:        Enabled
```

No Umbra environment variables are required for the default deployment.

---

# Default Umbra User

```text
ID:    shinusterben
Alias: shinu
```

The Docker image works immediately with these built-in defaults.

---

# Cloud Run URL

After deployment, Google Cloud Run gives you a public URL.

Example:

```text
https://erwan-xxxxxxxxxx-uc.a.run.app
```

Use the exact URL returned by Cloud Run.

---

# Subscription

Default subscription:

```text
https://YOUR-CLOUD-RUN-URL/sub/shinu
```

Example:

```text
https://erwan-xxxxxxxxxx-uc.a.run.app/sub/shinu
```

Plain subscription:

```text
https://YOUR-CLOUD-RUN-URL/sub/shinu/plain
```

Example:

```text
https://erwan-xxxxxxxxxx-uc.a.run.app/sub/shinu/plain
```

There is **no public `:8080`** in the Cloud Run URL.

Port `8080` is only used internally by the Cloud Run container.

---

# Default Inbounds

Umbra currently includes:

```text
VLESS + XHTTP
/vless/xhttp/shinu

VLESS + WebSocket
/vless/ws/shinu

VLESS + gRPC
serviceName: vless/grpc/shinu

Trojan + WebSocket
/trojan/ws/shinu

VMess + WebSocket
/vmess/ws/shinu
```

---

# Umbra Cloud Shell Dashboard

After installation, run:

```bash
umbra
```

Example dashboard:

```text
========================================================================
                       UMBRA CLOUD RUN
========================================================================

Project:            qwiklabs-gcp-xxxxxxxx
Region:             us-central1
Service:            erwan
Revision:           erwan-00001-xxx

========================================================================
                         CONTAINER
========================================================================

Image:              docker.io/noahclanman/gcp:latest
Port:               8080
Memory:             512Mi
CPU:                1

========================================================================
                         CLOUD RUN
========================================================================

Concurrency:        500
Max Instances:      16
Timeout:            3600s
Execution Env:      Second Generation
HTTP/2:             Enabled
Public Access:      Enabled

========================================================================
                          ACCESS
========================================================================

Cloud Run URL:
https://erwan-xxxxxxxxxx-uc.a.run.app

Subscription:
https://erwan-xxxxxxxxxx-uc.a.run.app/sub/shinu

Plain Subscription:
https://erwan-xxxxxxxxxx-uc.a.run.app/sub/shinu/plain
```

---

# Umbra Menu

Run:

```bash
umbra
```

Menu:

```text
[1] Refresh dashboard
[2] Show subscription / inbounds
[3] Show Cloud Run logs
[4] Redeploy latest Docker image
[5] Change service name
[6] Change region
[7] Delete Cloud Run service
[0] Exit
```

---

# Umbra Commands

Show Cloud Run dashboard:

```bash
umbra status
```

Show subscription and inbound details:

```bash
umbra links
```

Show Cloud Run logs:

```bash
umbra logs
```

Redeploy the latest Docker image:

```bash
umbra update
```

Open the full menu:

```bash
umbra
```

---

# Docker Hub Image

Umbra Docker image:

```text
docker.io/noahclanman/gcp:latest
```

This is the same image used by the shell installer.

---

# Deploy Docker Image Manually from Cloud Shell

You do not have to use `install.sh`.

You can deploy the Docker image manually from Google Cloud Shell.

Example:

```bash
gcloud run deploy umbra \
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
  --use-http2 \
  --allow-unauthenticated
```

After deployment, get the Cloud Run URL:

```bash
gcloud run services describe umbra \
  --region us-central1 \
  --format='value(status.url)'
```

Example result:

```text
https://umbra-xxxxxxxxxx-uc.a.run.app
```

Your subscription is then:

```text
https://umbra-xxxxxxxxxx-uc.a.run.app/sub/shinu
```

---

# Deploy from Google Cloud Console

You can also deploy the Docker image using the Google Cloud Console UI.

Go to:

```text
Google Cloud Console
→ Cloud Run
→ Create Service / Deploy Container
```

Use this image:

```text
docker.io/noahclanman/gcp:latest
```

Container port:

```text
8080
```

Recommended settings:

```text
Memory:               512Mi
CPU:                  1
Concurrency:          500
Max instances:        16
Timeout:              3600 seconds
Execution environment: Second Generation
HTTP/2:               Enabled
Public access:        Enabled
```

No environment variables are required for the default Umbra deployment.

---

# Google Cloud Skills Boost / Qwiklabs

This project can also be used from a Google Cloud Skills Boost lab.

Typical flow:

```text
1. Start the Google Cloud Skills Boost lab

2. Open Google Cloud Console

3. Open Cloud Shell

4. Run:

   curl -fsSL https://raw.githubusercontent.com/noahclanman/gcp-shell/main/install.sh | bash

5. Choose your Cloud Run service name

6. Choose your Cloud Run region

7. Wait for deployment

8. Copy the generated *.run.app URL

9. Use:

   https://YOUR-CLOUD-RUN-URL/sub/shinu
```

---

# Check Current Google Cloud Project

```bash
gcloud config get-value project
```

---

# List Cloud Run Services

```bash
gcloud run services list
```

---

# Describe Cloud Run Service

Example:

```bash
gcloud run services describe umbra \
  --region us-central1
```

---

# Get Cloud Run URL

```bash
gcloud run services describe umbra \
  --region us-central1 \
  --format='value(status.url)'
```

---

# View Cloud Run Logs

Using Umbra:

```bash
umbra logs
```

Or manually:

```bash
gcloud run services logs read umbra \
  --region us-central1
```

---

# Update Umbra

The easiest method:

```bash
umbra update
```

This redeploys the latest:

```text
docker.io/noahclanman/gcp:latest
```

You can also redeploy manually:

```bash
gcloud run deploy umbra \
  --image docker.io/noahclanman/gcp:latest \
  --region us-central1
```

---

# Delete Cloud Run Service

Open the menu:

```bash
umbra
```

Then select:

```text
[7] Delete Cloud Run service
```

Or delete manually:

```bash
gcloud run services delete umbra \
  --region us-central1
```

---

# Custom Umbra User

The Docker image already has:

```text
shinusterben:shinu
```

as the default.

You can optionally override it using:

```text
USERS=myusername:myalias
```

Example:

```bash
gcloud run deploy umbra \
  --image docker.io/noahclanman/gcp:latest \
  --region us-central1 \
  --set-env-vars USERS="noah:noah" \
  --allow-unauthenticated
```

The subscription becomes:

```text
https://YOUR-CLOUD-RUN-URL/sub/noah
```

---

# Multiple Users

Example:

```text
USERS=shinusterben:shinu,noah:noah,user3:user3
```

Subscriptions:

```text
/sub/shinu
/sub/noah
/sub/user3
```

Each alias receives its own subscription.

---

# Optional Environment Variables

The default deployment does not require environment variables.

Optional settings:

```text
USERS
ENABLE_VMESS
ENABLE_GRPC
MAX_DEVICES
DEVICE_WINDOW
DEVICE_INTERVAL
TROJAN_PASSWORD
SHOW_LINKS
```

VMess and gRPC are enabled by default in the current Docker image.

---

# Check Umbra Homepage

After deployment:

```bash
curl https://YOUR-CLOUD-RUN-URL/
```

---

# Test Subscription

```bash
curl https://YOUR-CLOUD-RUN-URL/sub/shinu
```

---

# Test Plain Subscription

```bash
curl https://YOUR-CLOUD-RUN-URL/sub/shinu/plain
```

---

# Important

`gcp-shell` does **not** run Umbra permanently inside the temporary Cloud Shell machine.

Cloud Shell is used to execute the deployment commands.

The actual Docker image:

```text
docker.io/noahclanman/gcp:latest
```

runs on:

```text
Google Cloud Run
```

and Google Cloud Run provides the public:

```text
*.run.app
```

URL.

---

# Repositories

GCP Shell installer:

```text
https://github.com/noahclanman/gcp-shell
```

Main Umbra Docker project:

```text
https://github.com/noahclanman/gcp
```

Docker Hub image:

```text
docker.io/noahclanman/gcp:latest
```

---

# Quick Reference

Install from Google Cloud Shell:

```bash
curl -fsSL https://raw.githubusercontent.com/noahclanman/gcp-shell/main/install.sh | bash
```

Open dashboard:

```bash
umbra
```

Show status:

```bash
umbra status
```

Show links:

```bash
umbra links
```

Show logs:

```bash
umbra logs
```

Update:

```bash
umbra update
```

Docker image:

```text
docker.io/noahclanman/gcp:latest
```

Default subscription:

```text
https://YOUR-CLOUD-RUN-URL/sub/shinu
```
