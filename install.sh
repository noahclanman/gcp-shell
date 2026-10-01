#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE_DEFAULT="docker.io/noahclanman/gcp:latest"
SERVICE_DEFAULT="umbra"
REGION_DEFAULT="us-central1"

CONFIG_DIR="${HOME}/.config/umbra"
CONFIG_FILE="${CONFIG_DIR}/cloudrun.env"
BIN_DIR="${HOME}/.local/bin"
BIN_FILE="${BIN_DIR}/umbra"

line() {
  printf '%*s\n' 68 '' | tr ' ' '='
}

die() {
  echo "[ERROR] $*" >&2
  exit 1
}

prompt_tty() {
  local prompt="$1"
  local default="$2"
  local answer=""

  if [ -r /dev/tty ]; then
    read -r -p "$prompt [$default]: " answer < /dev/tty || true
  fi

  printf '%s' "${answer:-$default}"
}

command -v gcloud >/dev/null 2>&1 || die "gcloud is not installed. Run this from Google Cloud Shell / Skills Boost Cloud Shell."

ACCOUNT="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | head -n1 || true)"
[ -n "$ACCOUNT" ] || die "No active Google Cloud account. Authenticate gcloud first."

PROJECT_ID="$(gcloud config get-value project 2>/dev/null || true)"
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-}"
fi
[ -n "$PROJECT_ID" ] || die "No active Google Cloud project. Select your Skills Boost / GCP project first."

SERVICE_NAME="${SERVICE_NAME:-$(prompt_tty "Cloud Run service name" "$SERVICE_DEFAULT")}"
REGION="${REGION:-$(prompt_tty "Cloud Run region" "$REGION_DEFAULT")}"
IMAGE="${IMAGE:-$IMAGE_DEFAULT}"

if ! [[ "$SERVICE_NAME" =~ ^[a-z]([a-z0-9-]{0,47}[a-z0-9])?$ ]]; then
  die "Invalid service name. Use lowercase letters, numbers and hyphens; start with a letter; max 49 characters."
fi

if ! [[ "$REGION" =~ ^[a-z0-9-]+$ ]]; then
  die "Invalid region: $REGION"
fi

mkdir -p "$CONFIG_DIR" "$BIN_DIR"

cat > "$CONFIG_FILE" <<EOF
PROJECT_ID='$PROJECT_ID'
SERVICE_NAME='$SERVICE_NAME'
REGION='$REGION'
IMAGE='$IMAGE'
EOF

cat > "$BIN_FILE" <<'UMBRA_MANAGER'
#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_FILE="${HOME}/.config/umbra/cloudrun.env"

[ -f "$CONFIG_FILE" ] || {
  echo "[ERROR] Umbra config not found: $CONFIG_FILE" >&2
  exit 1
}

# shellcheck disable=SC1090
source "$CONFIG_FILE"

PORT="8080"
MEMORY="512Mi"
CPU="1"
CONCURRENCY="500"
MAX_INSTANCES="16"
TIMEOUT="3600"

line() {
  printf '%*s\n' 72 '' | tr ' ' '='
}

pause_menu() {
  echo
  read -r -p "Press Enter to continue..." < /dev/tty || true
}

service_exists() {
  gcloud run services describe "$SERVICE_NAME" \
    --project "$PROJECT_ID" \
    --region "$REGION" \
    >/dev/null 2>&1
}

service_url() {
  gcloud run services describe "$SERVICE_NAME" \
    --project "$PROJECT_ID" \
    --region "$REGION" \
    --format='value(status.url)' 2>/dev/null
}

latest_revision() {
  gcloud run services describe "$SERVICE_NAME" \
    --project "$PROJECT_ID" \
    --region "$REGION" \
    --format='value(status.latestReadyRevisionName)' 2>/dev/null
}

deploy() {
  line
  echo "                    UMBRA CLOUD RUN DEPLOY"
  line
  echo "Project : $PROJECT_ID"
  echo "Region  : $REGION"
  echo "Service : $SERVICE_NAME"
  echo "Image   : $IMAGE"
  echo
  echo "Deploying..."
  echo

  gcloud services enable run.googleapis.com \
    --project "$PROJECT_ID" \
    --quiet

  gcloud run deploy "$SERVICE_NAME" \
    --project "$PROJECT_ID" \
    --region "$REGION" \
    --image "$IMAGE" \
    --port "$PORT" \
    --allow-unauthenticated \
    --execution-environment gen2 \
    --cpu "$CPU" \
    --memory "$MEMORY" \
    --concurrency "$CONCURRENCY" \
    --max-instances "$MAX_INSTANCES" \
    --min-instances 0 \
    --timeout "$TIMEOUT" \
    --use-http2 \
    --cpu-boost \
    --ingress all \
    --quiet

  echo
  dashboard
}

dashboard() {
  clear 2>/dev/null || true

  line
  echo "                       UMBRA CLOUD RUN"
  line

  if ! service_exists; then
    echo
    echo "Status: NOT DEPLOYED"
    echo
    echo "Project: $PROJECT_ID"
    echo "Region : $REGION"
    echo "Service: $SERVICE_NAME"
    echo "Image  : $IMAGE"
    echo
    line
    return
  fi

  local url revision
  url="$(service_url)"
  revision="$(latest_revision)"

  echo
  printf " %-20s %s\n" "Project:" "$PROJECT_ID"
  printf " %-20s %s\n" "Region:" "$REGION"
  printf " %-20s %s\n" "Service:" "$SERVICE_NAME"
  printf " %-20s %s\n" "Revision:" "${revision:-unknown}"

  echo
  line
  echo "                         CONTAINER"
  line
  printf " %-20s %s\n" "Image:" "$IMAGE"
  printf " %-20s %s\n" "Port:" "$PORT"
  printf " %-20s %s\n" "Memory:" "$MEMORY"
  printf " %-20s %s\n" "CPU:" "$CPU"

  echo
  line
  echo "                         CLOUD RUN"
  line
  printf " %-20s %s\n" "Concurrency:" "$CONCURRENCY"
  printf " %-20s %s\n" "Max Instances:" "$MAX_INSTANCES"
  printf " %-20s %s\n" "Min Instances:" "0"
  printf " %-20s %ss\n" "Timeout:" "$TIMEOUT"
  printf " %-20s %s\n" "Execution Env:" "Second Generation"
  printf " %-20s %s\n" "HTTP/2:" "Enabled"
  printf " %-20s %s\n" "Public Access:" "Enabled"
  printf " %-20s %s\n" "CPU Boost:" "Enabled"

  echo
  line
  echo "                         PROTOCOLS"
  line
  printf " %-20s %s\n" "VLESS XHTTP:" "ON"
  printf " %-20s %s\n" "VLESS WebSocket:" "ON"
  printf " %-20s %s\n" "VLESS gRPC:" "ON"
  printf " %-20s %s\n" "Trojan WebSocket:" "ON"
  printf " %-20s %s\n" "VMess WebSocket:" "ON"

  echo
  line
  echo "                          ACCESS"
  line
  printf " %-20s %s\n" "Cloud Run URL:" "$url"
  printf " %-20s %s/sub/shinu\n" "Subscription:" "$url"
  printf " %-20s %s/sub/shinu/plain\n" "Plain Sub:" "$url"
  line
}

links() {
  if ! service_exists; then
    echo "Umbra is not deployed."
    return 1
  fi

  local url
  url="$(service_url)"

  clear 2>/dev/null || true
  line
  echo "                       UMBRA LINKS"
  line
  echo
  echo "Cloud Run URL:"
  echo "  $url"
  echo
  echo "Subscription:"
  echo "  $url/sub/shinu"
  echo
  echo "Plain Subscription:"
  echo "  $url/sub/shinu/plain"
  echo
  echo "Inbounds:"
  echo "  VLESS XHTTP      /vless/xhttp/shinu"
  echo "  VLESS WebSocket  /vless/ws/shinu"
  echo "  VLESS gRPC       serviceName: vless/grpc/shinu"
  echo "  Trojan WebSocket /trojan/ws/shinu"
  echo "  VMess WebSocket  /vmess/ws/shinu"
  echo
  line
}

logs() {
  if ! service_exists; then
    echo "Umbra is not deployed."
    return 1
  fi

  gcloud run services logs read "$SERVICE_NAME" \
    --project "$PROJECT_ID" \
    --region "$REGION" \
    --limit=50
}

save_config() {
  cat > "$CONFIG_FILE" <<EOF
PROJECT_ID='$PROJECT_ID'
SERVICE_NAME='$SERVICE_NAME'
REGION='$REGION'
IMAGE='$IMAGE'
EOF
}

change_service() {
  local value=""
  read -r -p "New Cloud Run service name [$SERVICE_NAME]: " value < /dev/tty || true
  [ -n "$value" ] || return 0

  if ! [[ "$value" =~ ^[a-z]([a-z0-9-]{0,47}[a-z0-9])?$ ]]; then
    echo "Invalid service name."
    return 1
  fi

  SERVICE_NAME="$value"
  save_config
  echo "Service changed to: $SERVICE_NAME"
}

change_region() {
  local value=""
  read -r -p "New Cloud Run region [$REGION]: " value < /dev/tty || true
  [ -n "$value" ] || return 0

  if ! [[ "$value" =~ ^[a-z0-9-]+$ ]]; then
    echo "Invalid region."
    return 1
  fi

  REGION="$value"
  save_config
  echo "Region changed to: $REGION"
}

delete_service() {
  if ! service_exists; then
    echo "Umbra is not deployed."
    return 0
  fi

  local answer=""
  read -r -p "Delete Cloud Run service '$SERVICE_NAME' in '$REGION'? [y/N]: " answer < /dev/tty || true

  case "$answer" in
    y|Y|yes|YES)
      gcloud run services delete "$SERVICE_NAME" \
        --project "$PROJECT_ID" \
        --region "$REGION" \
        --quiet
      echo "Service deleted."
      ;;
    *)
      echo "Cancelled."
      ;;
  esac
}

menu() {
  while true; do
    dashboard
    echo
    echo " [1] Refresh dashboard"
    echo " [2] Show subscription / inbounds"
    echo " [3] Show Cloud Run logs"
    echo " [4] Redeploy latest Docker image"
    echo " [5] Change service name"
    echo " [6] Change region"
    echo " [7] Delete Cloud Run service"
    echo " [0] Exit"
    echo

    local choice=""
    read -r -p " Select option: " choice < /dev/tty || true

    case "$choice" in
      1) ;;
      2) links; pause_menu ;;
      3) clear 2>/dev/null || true; logs; pause_menu ;;
      4) clear 2>/dev/null || true; deploy; pause_menu ;;
      5) change_service; pause_menu ;;
      6) change_region; pause_menu ;;
      7) delete_service; pause_menu ;;
      0) clear 2>/dev/null || true; exit 0 ;;
      *) echo "Invalid option."; sleep 1 ;;
    esac
  done
}

case "${1:-}" in
  deploy|update|redeploy)
    deploy
    ;;
  status|dashboard)
    dashboard
    ;;
  links|sub)
    links
    ;;
  logs)
    logs
    ;;
  delete|remove)
    delete_service
    ;;
  *)
    menu
    ;;
esac
UMBRA_MANAGER

chmod +x "$BIN_FILE"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    export PATH="$BIN_DIR:$PATH"
    if [ -f "${HOME}/.bashrc" ] && ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "${HOME}/.bashrc"; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
    fi
    ;;
esac

line
echo "                  UMBRA GCP SHELL INSTALLER"
line
echo
echo "Account : $ACCOUNT"
echo "Project : $PROJECT_ID"
echo "Region  : $REGION"
echo "Service : $SERVICE_NAME"
echo "Image   : $IMAGE"
echo
echo "This deploys your public Docker Hub image directly to Cloud Run."
echo "No Docker pull/run on the Cloud Shell machine is used."
echo
line
echo

"$BIN_FILE" deploy

echo
echo "Umbra Cloud Run manager installed:"
echo
echo "  umbra"
echo
echo "Useful commands:"
echo "  umbra status"
echo "  umbra links"
echo "  umbra logs"
echo "  umbra update"
echo
