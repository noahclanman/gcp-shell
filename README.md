# Umbra GCP Shell

Simple shell installer and dashboard for running the Umbra Docker image:

```text
docker.io/noahclanman/gcp:latest
```

This project installs Umbra as a Docker container and adds a shell command:

```bash
umbra
```

The `umbra` command opens a dashboard/menu for server specs, container status, logs, updates, restart, stop/start, subscription links, and inbound paths.

---

## Requirements

You need:

- Linux server / VPS / Google Cloud Shell VM
- Docker installed
- Internet connection
- `curl` recommended

Check Docker:

```bash
docker --version
```

Check Docker daemon:

```bash
docker info
```

---

## Quick Install

Run:

```bash
curl -fsSL https://raw.githubusercontent.com/noahclanman/gcp-shell/main/install.sh | bash
```

The installer will:

- pull the latest Umbra Docker image
- remove the old Umbra container if it exists
- create a new Umbra container
- expose port `8080`
- install the `umbra` shell command
- show the server dashboard after installation

---

## Open Umbra Dashboard

After installation:

```bash
umbra
```

The dashboard shows:

```text
OS
Kernel
Architecture
CPU / vCPU
CPU model
Memory usage
Disk usage
Load average
Uptime
Public IP
Local IP

Umbra container status
Docker state
Docker image
Container start time
Published ports
Subscription URL
```

---

## Umbra Menu

Run:

```bash
umbra
```

Menu:

```text
[1] Refresh dashboard
[2] Subscription / inbound paths
[3] Container resource usage
[4] View live logs
[5] Restart Umbra
[6] Update Umbra
[7] Stop Umbra
[8] Start Umbra
[9] Remove Umbra container
[0] Exit
```

---

## Shell Commands

Show dashboard:

```bash
umbra status
```

Show subscription and inbound paths:

```bash
umbra links
```

Show Docker resource usage:

```bash
umbra stats
```

View live logs:

```bash
umbra logs
```

Restart Umbra:

```bash
umbra restart
```

Update to the latest Docker image:

```bash
umbra update
```

Stop Umbra:

```bash
umbra stop
```

Start Umbra:

```bash
umbra start
```

---

## Default Umbra Configuration

Default user:

```text
ID: shinusterben
Alias: shinu
```

Default subscription:

```text
http://YOUR_SERVER_IP:8080/sub/shinu
```

Plain subscription:

```text
http://YOUR_SERVER_IP:8080/sub/shinu/plain
```

Default inbound paths:

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

## Using Docker Directly

You do not have to use the shell installer.

Docker image:

```text
docker.io/noahclanman/gcp:latest
```

Pull the image:

```bash
docker pull noahclanman/gcp:latest
```

Run the container:

```bash
docker run -d \
  --name umbra \
  --restart unless-stopped \
  -p 8080:8080 \
  noahclanman/gcp:latest
```

Check status:

```bash
docker ps
```

View logs:

```bash
docker logs -f umbra
```

Restart:

```bash
docker restart umbra
```

Stop:

```bash
docker stop umbra
```

Start:

```bash
docker start umbra
```

Remove:

```bash
docker rm -f umbra
```

---

## Update Docker Image Manually

Pull the latest version:

```bash
docker pull noahclanman/gcp:latest
```

Remove the current container:

```bash
docker rm -f umbra
```

Start the latest image:

```bash
docker run -d \
  --name umbra \
  --restart unless-stopped \
  -p 8080:8080 \
  noahclanman/gcp:latest
```

Or simply use:

```bash
umbra update
```

---

## Custom Users

The Docker image works without adding variables.

Default:

```text
shinusterben:shinu
```

You can optionally override it:

```bash
docker run -d \
  --name umbra \
  --restart unless-stopped \
  -p 8080:8080 \
  -e USERS="myusername:myalias" \
  noahclanman/gcp:latest
```

Example:

```bash
docker run -d \
  --name umbra \
  --restart unless-stopped \
  -p 8080:8080 \
  -e USERS="noah:noah" \
  noahclanman/gcp:latest
```

Subscription:

```text
http://YOUR_SERVER_IP:8080/sub/noah
```

Multiple users:

```bash
-e USERS="shinusterben:shinu,noah:noah,user3:user3"
```

Each alias gets its own subscription:

```text
/sub/shinu
/sub/noah
/sub/user3
```

---

## Optional Environment Variables

VMess and gRPC are enabled by default.

Example:

```bash
docker run -d \
  --name umbra \
  --restart unless-stopped \
  -p 8080:8080 \
  -e ENABLE_VMESS=1 \
  -e ENABLE_GRPC=1 \
  noahclanman/gcp:latest
```

Other optional settings:

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

---

## Check Container Health

```bash
docker inspect umbra
```

Quick HTTP test:

```bash
curl http://127.0.0.1:8080/
```

Subscription test:

```bash
curl http://127.0.0.1:8080/sub/shinu
```

Plain subscription:

```bash
curl http://127.0.0.1:8080/sub/shinu/plain
```

---

## Firewall

Make sure TCP port `8080` is allowed if you want to access Umbra directly from the internet.

Example with UFW:

```bash
sudo ufw allow 8080/tcp
```

Check:

```bash
sudo ufw status
```

---

## Repository

Shell installer:

```text
https://github.com/noahclanman/gcp-shell
```

Docker image:

```text
docker.io/noahclanman/gcp:latest
```

Main Docker project:

```text
https://github.com/noahclanman/gcp
```

---

## Quick Reference

Install:

```bash
curl -fsSL https://raw.githubusercontent.com/noahclanman/gcp-shell/main/install.sh | bash
```

Dashboard:

```bash
umbra
```

Update:

```bash
umbra update
```

Logs:

```bash
umbra logs
```

Docker image:

```text
docker.io/noahclanman/gcp:latest
```
