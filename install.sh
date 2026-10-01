#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# XVPN - Google Cloud Shell -> Cloud Run Installer / Manager
# by shinusterben
# ============================================================

IMAGE="docker.io/noahclanman/gcp:latest"
DEFAULT_SERVICE="xvpn"
DEFAULT_REGION="us-central1"

PORT="8080"
MEMORY="512Mi"
CPU="1"
CONCURRENCY="500"
MAX_INSTANCES="16"
TIMEOUT="3600"

CONFIG_DIR="${HOME}/.config/xvpn"
CONFIG_FILE="${CONFIG_DIR}/config"
BIN_DIR="${HOME}/.local/bin"
XVPN_BIN="${BIN_DIR}/xvpn"

# ------------------------------------------------------------
# COLORS
# ------------------------------------------------------------

if [ -t 1 ]; then
    GREEN='\033[0;32m'
    CYAN='\033[0;36m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    GREEN=''
    CYAN=''
    YELLOW=''
    RED=''
    BOLD=''
    RESET=''
fi

line() {
    printf '%*s\n' 72 '' | tr ' ' '='
}

info() {
    printf "${CYAN}[INFO]${RESET} %s\n" "$*"
}

success() {
    printf "${GREEN}[OK]${RESET} %s\n" "$*"
}

warn() {
    printf "${YELLOW}[WARN]${RESET} %s\n" "$*"
}

die() {
    printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2
    exit 1
}

# ------------------------------------------------------------
# REQUIREMENTS
# ------------------------------------------------------------

command -v gcloud >/dev/null 2>&1 || \
    die "gcloud CLI was not found. Run this from Google Cloud Shell."

PROJECT="$(gcloud config get-value project 2>/dev/null || true)"

if [ -z "$PROJECT" ] || [ "$PROJECT" = "(unset)" ]; then
    die "No Google Cloud project is selected."
fi

# ------------------------------------------------------------
# INPUT
# ------------------------------------------------------------

echo
line
echo "                     XVPN CLOUD RUN INSTALLER"
echo "                         by shinusterben"
line
echo
echo "Project:"
echo "  $PROJECT"
echo

read -r -p "Cloud Run service name [${DEFAULT_SERVICE}]: " SERVICE
SERVICE="${SERVICE:-$DEFAULT_SERVICE}"

read -r -p "Cloud Run region [${DEFAULT_REGION}]: " REGION
REGION="${REGION:-$DEFAULT_REGION}"

if ! [[ "$SERVICE" =~ ^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$ ]]; then
    die "Invalid Cloud Run service name."
fi

if ! [[ "$REGION" =~ ^[a-z0-9-]+$ ]]; then
    die "Invalid Cloud Run region."
fi

echo
line
echo " Deployment"
line
printf " %-20s %s\n" "Project:" "$PROJECT"
printf " %-20s %s\n" "Service:" "$SERVICE"
printf " %-20s %s\n" "Region:" "$REGION"
printf " %-20s %s\n" "Image:" "$IMAGE"
printf " %-20s %s\n" "Port:" "$PORT"
line
echo

# ------------------------------------------------------------
# ENABLE CLOUD RUN API
# ------------------------------------------------------------

info "Checking Cloud Run API..."

gcloud services enable run.googleapis.com \
    --project "$PROJECT" \
    --quiet >/dev/null 2>&1 || true

# ------------------------------------------------------------
# DEPLOY
# ------------------------------------------------------------

info "Deploying XVPN to Google Cloud Run..."

gcloud run deploy "$SERVICE" \
    --project "$PROJECT" \
    --region "$REGION" \
    --platform managed \
    --image "$IMAGE" \
    --port "$PORT" \
    --memory "$MEMORY" \
    --cpu "$CPU" \
    --concurrency "$CONCURRENCY" \
    --max-instances "$MAX_INSTANCES" \
    --timeout "$TIMEOUT" \
    --execution-environment gen2 \
    --cpu-boost \
    --use-http2 \
    --allow-unauthenticated \
    --quiet

success "Cloud Run deployment completed."

# ------------------------------------------------------------
# SAVE SETTINGS
# ------------------------------------------------------------

mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_FILE" <<EOF
PROJECT="$PROJECT"
SERVICE="$SERVICE"
REGION="$REGION"
IMAGE="$IMAGE"
PORT="$PORT"
MEMORY="$MEMORY"
CPU="$CPU"
CONCURRENCY="$CONCURRENCY"
MAX_INSTANCES="$MAX_INSTANCES"
TIMEOUT="$TIMEOUT"
EOF

chmod 600 "$CONFIG_FILE"

# ------------------------------------------------------------
# CREATE XVPN MANAGER
# ------------------------------------------------------------

mkdir -p "$BIN_DIR"

cat > "$XVPN_BIN" <<'XVPN_SCRIPT'
#!/usr/bin/env bash
set -u

CONFIG_FILE="${HOME}/.config/xvpn/config"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "XVPN configuration was not found."
    echo "Run the installer again."
    exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

if [ -t 1 ]; then
    GREEN='\033[0;32m'
    CYAN='\033[0;36m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    RESET='\033[0m'
else
    GREEN=''
    CYAN=''
    YELLOW=''
    RED=''
    RESET=''
fi

line() {
    printf '%*s\n' 72 '' | tr ' ' '='
}

service_exists() {
    gcloud run services describe "$SERVICE" \
        --project "$PROJECT" \
        --region "$REGION" \
        >/dev/null 2>&1
}

get_url() {
    gcloud run services describe "$SERVICE" \
        --project "$PROJECT" \
        --region "$REGION" \
        --format='value(status.url)' \
        2>/dev/null
}

get_revision() {
    gcloud run services describe "$SERVICE" \
        --project "$PROJECT" \
        --region "$REGION" \
        --format='value(status.latestReadyRevisionName)' \
        2>/dev/null
}

get_image() {
    gcloud run services describe "$SERVICE" \
        --project "$PROJECT" \
        --region "$REGION" \
        --format='value(spec.template.spec.containers[0].image)' \
        2>/dev/null
}

dashboard() {
    clear 2>/dev/null || true

    local URL="-"
    local REVISION="-"
    local CURRENT_IMAGE="$IMAGE"
    local STATUS="NOT DEPLOYED"

    if service_exists; then
        URL="$(get_url)"
        REVISION="$(get_revision)"
        CURRENT_IMAGE="$(get_image)"
        STATUS="ONLINE"
    fi

    line
    echo "                         XVPN CLOUD RUN"
    echo "                           by shinusterben"
    line
    echo
    printf " %-22s %s\n" "Status:" "$STATUS"
    printf " %-22s %s\n" "Project:" "$PROJECT"
    printf " %-22s %s\n" "Region:" "$REGION"
    printf " %-22s %s\n" "Service:" "$SERVICE"
    printf " %-22s %s\n" "Revision:" "${REVISION:--}"
    echo
    line
    echo "                           CONTAINER"
    line
    echo
    printf " %-22s %s\n" "Image:" "${CURRENT_IMAGE:-$IMAGE}"
    printf " %-22s %s\n" "Port:" "$PORT"
    printf " %-22s %s\n" "Memory:" "$MEMORY"
    printf " %-22s %s\n" "CPU:" "$CPU"
    echo
    line
    echo "                           CLOUD RUN"
    line
    echo
    printf " %-22s %s\n" "Concurrency:" "$CONCURRENCY"
    printf " %-22s %s\n" "Max Instances:" "$MAX_INSTANCES"
    printf " %-22s %ss\n" "Timeout:" "$TIMEOUT"
    printf " %-22s %s\n" "Execution Env:" "Second Generation"
    printf " %-22s %s\n" "HTTP/2:" "Enabled"
    printf " %-22s %s\n" "CPU Boost:" "Enabled"
    printf " %-22s %s\n" "Public Access:" "Enabled"
    echo
    line
    echo "                           PROTOCOLS"
    line
    echo
    printf " %-26s %s\n" "VLESS + XHTTP" "ON"
    printf " %-26s %s\n" "VLESS + WebSocket" "ON"
    printf " %-26s %s\n" "VLESS + gRPC" "ON"
    printf " %-26s %s\n" "Trojan + WebSocket" "ON"
    printf " %-26s %s\n" "VMess + WebSocket" "ON"
    printf " %-26s %s\n" "Shadowsocks + WebSocket" "ON"
    echo
    line
    echo "                            ACCESS"
    line
    echo

    if [ "$STATUS" = "ONLINE" ]; then
        echo "Site:"
        echo "  ${URL}/"
        echo
        echo "XVPN Page:"
        echo "  ${URL}/xvpn/shinu"
        echo
        echo "Subscription:"
        echo "  ${URL}/sub/shinu"
    else
        echo "Cloud Run service is not currently deployed."
    fi

    echo
    line
}

links() {
    if ! service_exists; then
        echo "Cloud Run service does not exist."
        return 1
    fi

    local URL
    URL="$(get_url)"

    clear 2>/dev/null || true

    line
    echo "                           XVPN LINKS"
    line
    echo
    echo "Website:"
    echo "  ${URL}/"
    echo
    echo "XVPN Profile:"
    echo "  ${URL}/xvpn/shinu"
    echo
    echo "Subscription:"
    echo "  ${URL}/sub/shinu"
    echo
    line
    echo "                         INBOUND PATHS"
    line
    echo
    echo "VLESS + XHTTP"
    echo "  /vless/xhttp/shinu"
    echo
    echo "VLESS + WebSocket"
    echo "  /vless/ws/shinu"
    echo
    echo "VLESS + gRPC"
    echo "  serviceName: vless/grpc/shinu"
    echo
    echo "Trojan + WebSocket"
    echo "  /trojan/ws/shinu"
    echo
    echo "VMess + WebSocket"
    echo "  /vmess/ws/shinu"
    echo
    echo "Shadowsocks + WebSocket"
    echo "  /shadowsocks/ws/shinu"
    echo
    line
}

logs() {
    if ! service_exists; then
        echo "Cloud Run service does not exist."
        return 1
    fi

    echo
    echo "Latest XVPN Cloud Run logs:"
    echo

    gcloud run services logs read "$SERVICE" \
        --project "$PROJECT" \
        --region "$REGION" \
        --limit 100
}

update_service() {
    echo
    echo "Redeploying latest XVPN image..."
    echo

    gcloud run deploy "$SERVICE" \
        --project "$PROJECT" \
        --region "$REGION" \
        --platform managed \
        --image "$IMAGE" \
        --port "$PORT" \
        --memory "$MEMORY" \
        --cpu "$CPU" \
        --concurrency "$CONCURRENCY" \
        --max-instances "$MAX_INSTANCES" \
        --timeout "$TIMEOUT" \
        --execution-environment gen2 \
        --cpu-boost \
        --use-http2 \
        --allow-unauthenticated \
        --quiet

    echo
    echo "XVPN redeployed successfully."
}

delete_service() {
    if ! service_exists; then
        echo "Cloud Run service does not exist."
        return
    fi

    echo
    read -r -p "Delete Cloud Run service '${SERVICE}'? [y/N]: " CONFIRM

    case "$CONFIRM" in
        y|Y|yes|YES)
            gcloud run services delete "$SERVICE" \
                --project "$PROJECT" \
                --region "$REGION" \
                --quiet
            echo
            echo "Service deleted."
            ;;
        *)
            echo "Cancelled."
            ;;
    esac
}

change_service() {
    local NEW_SERVICE

    echo
    read -r -p "New service name: " NEW_SERVICE

    if ! [[ "$NEW_SERVICE" =~ ^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$ ]]; then
        echo "Invalid service name."
        return
    fi

    SERVICE="$NEW_SERVICE"

    sed -i \
        "s/^SERVICE=.*/SERVICE=\"${SERVICE}\"/" \
        "$CONFIG_FILE"

    echo
    echo "Service changed to: $SERVICE"
}

change_region() {
    local NEW_REGION

    echo
    read -r -p "New region: " NEW_REGION

    if ! [[ "$NEW_REGION" =~ ^[a-z0-9-]+$ ]]; then
        echo "Invalid region."
        return
    fi

    REGION="$NEW_REGION"

    sed -i \
        "s/^REGION=.*/REGION=\"${REGION}\"/" \
        "$CONFIG_FILE"

    echo
    echo "Region changed to: $REGION"
}

pause_menu() {
    echo
    read -r -p "Press Enter to continue..."
}

menu() {
    while true; do
        dashboard

        echo
        echo " [1] Refresh dashboard"
        echo " [2] Show XVPN links / inbounds"
        echo " [3] Show Cloud Run logs"
        echo " [4] Redeploy latest Docker image"
        echo " [5] Change service name"
        echo " [6] Change region"
        echo " [7] Delete Cloud Run service"
        echo " [0] Exit"
        echo

        read -r -p " Select option: " CHOICE

        case "$CHOICE" in
            1)
                ;;
            2)
                links
                pause_menu
                ;;
            3)
                logs
                pause_menu
                ;;
            4)
                update_service
                pause_menu
                ;;
            5)
                change_service
                pause_menu
                ;;
            6)
                change_region
                pause_menu
                ;;
            7)
                delete_service
                pause_menu
                ;;
            0)
                clear 2>/dev/null || true
                exit 0
                ;;
            *)
                echo "Invalid option."
                sleep 1
                ;;
        esac
    done
}

case "${1:-}" in
    status|dashboard)
        dashboard
        ;;
    links|sub)
        links
        ;;
    logs)
        logs
        ;;
    update|deploy)
        update_service
        ;;
    delete)
        delete_service
        ;;
    *)
        menu
        ;;
esac
XVPN_SCRIPT

chmod +x "$XVPN_BIN"

# ------------------------------------------------------------
# ADD ~/.local/bin TO PATH
# ------------------------------------------------------------

if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    export PATH="${BIN_DIR}:$PATH"

    if ! grep -qs 'HOME/.local/bin' "${HOME}/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
    fi
fi

# ------------------------------------------------------------
# RESULT
# ------------------------------------------------------------

URL="$(gcloud run services describe "$SERVICE" \
    --project "$PROJECT" \
    --region "$REGION" \
    --format='value(status.url)' \
    2>/dev/null || true)"

REVISION="$(gcloud run services describe "$SERVICE" \
    --project "$PROJECT" \
    --region "$REGION" \
    --format='value(status.latestReadyRevisionName)' \
    2>/dev/null || true)"

echo
line
echo "                    XVPN DEPLOYMENT COMPLETE"
echo "                         by shinusterben"
line
echo
printf " %-20s %s\n" "Project:" "$PROJECT"
printf " %-20s %s\n" "Region:" "$REGION"
printf " %-20s %s\n" "Service:" "$SERVICE"
printf " %-20s %s\n" "Revision:" "${REVISION:--}"
printf " %-20s %s\n" "Image:" "$IMAGE"
echo

if [ -n "$URL" ]; then
    echo "Website:"
    echo "  ${URL}/"
    echo
    echo "XVPN Page:"
    echo "  ${URL}/xvpn/shinu"
    echo
    echo "Subscription:"
    echo "  ${URL}/sub/shinu"
fi

echo
echo "XVPN manager:"
echo
echo "  xvpn"
echo
echo "Commands:"
echo
echo "  xvpn status"
echo "  xvpn links"
echo "  xvpn logs"
echo "  xvpn update"
echo
line
echo

"$XVPN_BIN" status
