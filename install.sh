#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE="noahclanman/gcp:latest"
CONTAINER="umbra"
HOST_PORT="8080"
CONTAINER_PORT="8080"
MENU_BIN="/usr/local/bin/umbra"

line() {
    printf '%*s\n' 66 '' | tr ' ' '='
}

info() {
    echo "[INFO] $*"
}

die() {
    echo "[ERROR] $*" >&2
    exit 1
}

# =========================================================
# CHECK DOCKER
# =========================================================

if ! command -v docker >/dev/null 2>&1; then
    die "Docker is not installed."
fi

if ! docker info >/dev/null 2>&1; then
    die "Docker daemon is not running or your user cannot access Docker."
fi

line
echo "                    UMBRA INSTALLER"
line

# =========================================================
# PULL IMAGE FIRST
# =========================================================

info "Pulling latest Umbra image..."

docker pull "$IMAGE"

# Only remove the old container AFTER a successful pull.
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER"; then
    info "Removing old Umbra container..."
    docker rm -f "$CONTAINER" >/dev/null
fi

# =========================================================
# START UMBRA
# =========================================================

info "Starting Umbra..."

docker run -d \
    --name "$CONTAINER" \
    --restart unless-stopped \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    "$IMAGE" >/dev/null

sleep 3

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
    echo
    echo "Umbra failed to start."
    echo
    docker logs "$CONTAINER" 2>&1 || true
    exit 1
fi

# =========================================================
# CREATE UMBRA DASHBOARD COMMAND
# =========================================================

TMP_MENU="$(mktemp)"
trap 'rm -f "$TMP_MENU"' EXIT

cat > "$TMP_MENU" <<'UMBRA_MENU'
#!/usr/bin/env bash
set -u

IMAGE="noahclanman/gcp:latest"
CONTAINER="umbra"
HOST_PORT="8080"
CONTAINER_PORT="8080"

line() {
    printf '%*s\n' 68 '' | tr ' ' '='
}

docker_ok() {
    command -v docker >/dev/null 2>&1 &&
    docker info >/dev/null 2>&1
}

container_exists() {
    docker ps -a --format '{{.Names}}' 2>/dev/null |
        grep -qx "$CONTAINER"
}

container_running() {
    docker ps --format '{{.Names}}' 2>/dev/null |
        grep -qx "$CONTAINER"
}

get_public_ip() {
    local ip=""

    if command -v curl >/dev/null 2>&1; then
        ip="$(curl -4 -fsS --max-time 4 https://api.ipify.org 2>/dev/null || true)"
    elif command -v wget >/dev/null 2>&1; then
        ip="$(wget -qO- -T 4 https://api.ipify.org 2>/dev/null || true)"
    fi

    echo "$ip"
}

get_local_ip() {
    hostname -I 2>/dev/null | awk '{print $1}'
}

get_os() {
    if [ -r /etc/os-release ]; then
        . /etc/os-release
        echo "${PRETTY_NAME:-Linux}"
    else
        uname -s
    fi
}

get_cpu_model() {
    awk -F: '
        /model name/ {
            gsub(/^[ \t]+/, "", $2)
            print $2
            exit
        }
    ' /proc/cpuinfo 2>/dev/null
}

get_cpu_count() {
    getconf _NPROCESSORS_ONLN 2>/dev/null ||
    nproc 2>/dev/null ||
    echo "?"
}

get_memory_total() {
    free -h 2>/dev/null | awk '/^Mem:/ {print $2}'
}

get_memory_used() {
    free -h 2>/dev/null | awk '/^Mem:/ {print $3}'
}

get_disk_total() {
    df -h / 2>/dev/null | awk 'NR==2 {print $2}'
}

get_disk_used() {
    df -h / 2>/dev/null | awk 'NR==2 {print $3}'
}

get_disk_percent() {
    df -h / 2>/dev/null | awk 'NR==2 {print $5}'
}

get_uptime() {
    uptime -p 2>/dev/null ||
    uptime 2>/dev/null ||
    echo "Unknown"
}

get_load() {
    awk '{print $1", "$2", "$3}' /proc/loadavg 2>/dev/null ||
    echo "-"
}

pause_menu() {
    echo
    read -r -p "Press Enter to continue..."
}

dashboard() {

    local status="-"
    local image="-"
    local started="-"
    local ports="-"
    local health="-"

    local public_ip
    local local_ip

    public_ip="$(get_public_ip)"
    local_ip="$(get_local_ip)"

    [ -n "$public_ip" ] || public_ip="Unavailable"
    [ -n "$local_ip" ] || local_ip="Unavailable"

    if container_exists; then

        status="$(
            docker inspect \
                -f '{{.State.Status}}' \
                "$CONTAINER" 2>/dev/null ||
            echo "Unknown"
        )"

        image="$(
            docker inspect \
                -f '{{.Config.Image}}' \
                "$CONTAINER" 2>/dev/null ||
            echo "-"
        )"

        started="$(
            docker inspect \
                -f '{{.State.StartedAt}}' \
                "$CONTAINER" 2>/dev/null |
            cut -d. -f1 |
            tr 'T' ' '
        )"

        ports="$(
            docker port "$CONTAINER" 2>/dev/null |
            paste -sd ',' - ||
            true
        )"

        [ -n "$ports" ] || ports="-"

        if container_running; then
            health="ONLINE"
        else
            health="OFFLINE"
        fi
    fi

    clear 2>/dev/null || true

    line
    echo "                       UMBRA DASHBOARD"
    line

    printf " %-20s %s\n" "OS:" "$(get_os)"
    printf " %-20s %s\n" "Kernel:" "$(uname -r)"
    printf " %-20s %s\n" "Architecture:" "$(uname -m)"
    printf " %-20s %s vCPU\n" "CPU:" "$(get_cpu_count)"

    CPU_MODEL="$(get_cpu_model)"
    if [ -n "$CPU_MODEL" ]; then
        printf " %-20s %s\n" "CPU Model:" "$CPU_MODEL"
    fi

    printf " %-20s %s / %s\n" \
        "Memory:" \
        "$(get_memory_used)" \
        "$(get_memory_total)"

    printf " %-20s %s / %s (%s)\n" \
        "Disk:" \
        "$(get_disk_used)" \
        "$(get_disk_total)" \
        "$(get_disk_percent)"

    printf " %-20s %s\n" "Load Average:" "$(get_load)"
    printf " %-20s %s\n" "Uptime:" "$(get_uptime)"

    echo
    line
    echo "                       NETWORK"
    line

    printf " %-20s %s\n" "Public IP:" "$public_ip"
    printf " %-20s %s\n" "Local IP:" "$local_ip"

    echo
    line
    echo "                       UMBRA SERVICE"
    line

    printf " %-20s %s\n" "Status:" "$health"
    printf " %-20s %s\n" "Container:" "$CONTAINER"
    printf " %-20s %s\n" "Docker State:" "$status"
    printf " %-20s %s\n" "Image:" "$image"
    printf " %-20s %s\n" "Started:" "$started"
    printf " %-20s %s\n" "Ports:" "$ports"

    echo
    line
    echo "                       UMBRA ACCESS"
    line

    printf " %-20s http://%s:%s/sub/shinu\n" \
        "Subscription:" \
        "$public_ip" \
        "$HOST_PORT"

    printf " %-20s http://%s:%s/sub/shinu/plain\n" \
        "Plain:" \
        "$public_ip" \
        "$HOST_PORT"

    line
}

show_links() {

    local ip

    ip="$(get_public_ip)"

    if [ -z "$ip" ]; then
        ip="$(get_local_ip)"
    fi

    if [ -z "$ip" ]; then
        ip="YOUR_SERVER_IP"
    fi

    clear 2>/dev/null || true

    line
    echo "                      UMBRA LINKS"
    line

    echo
    echo "Subscription:"
    echo
    echo "http://${ip}:${HOST_PORT}/sub/shinu"

    echo
    echo "Plain Subscription:"
    echo
    echo "http://${ip}:${HOST_PORT}/sub/shinu/plain"

    echo
    echo "Inbound Paths:"
    echo

    echo "VLESS XHTTP"
    echo "  /vless/xhttp/shinu"

    echo
    echo "VLESS WebSocket"
    echo "  /vless/ws/shinu"

    echo
    echo "VLESS gRPC"
    echo "  vless/grpc/shinu"

    echo
    echo "Trojan WebSocket"
    echo "  /trojan/ws/shinu"

    echo
    echo "VMess WebSocket"
    echo "  /vmess/ws/shinu"

    echo
    line
}

show_container_stats() {

    if ! container_running; then
        echo "Umbra is not running."
        return
    fi

    docker stats \
        --no-stream \
        --format \
'Container: {{.Name}}
CPU:       {{.CPUPerc}}
Memory:    {{.MemUsage}}
Memory %:  {{.MemPerc}}
Network:   {{.NetIO}}
Block IO:  {{.BlockIO}}
PIDs:      {{.PIDs}}' \
        "$CONTAINER"
}

restart_umbra() {

    if container_exists; then

        echo "Restarting Umbra..."

        docker restart "$CONTAINER" >/dev/null

        echo "Umbra restarted successfully."

    else
        echo "Umbra container does not exist."
    fi
}

stop_umbra() {

    if container_running; then

        echo "Stopping Umbra..."

        docker stop "$CONTAINER"

    else
        echo "Umbra is already stopped."
    fi
}

start_umbra() {

    if container_exists; then

        echo "Starting Umbra..."

        docker start "$CONTAINER"

    else
        echo "Umbra container does not exist."
        echo "Run the installer again."
    fi
}

update_umbra() {

    echo
    echo "Pulling latest Umbra image..."

    if ! docker pull "$IMAGE"; then
        echo
        echo "Image pull failed."
        echo "Existing Umbra container was NOT removed."
        return 1
    fi

    echo
    echo "Image downloaded successfully."

    if container_exists; then
        echo "Removing old container..."
        docker rm -f "$CONTAINER" >/dev/null
    fi

    echo "Starting latest Umbra..."

    docker run -d \
        --name "$CONTAINER" \
        --restart unless-stopped \
        -p "${HOST_PORT}:${CONTAINER_PORT}" \
        "$IMAGE" >/dev/null

    sleep 3

    if container_running; then
        echo
        echo "Umbra updated successfully."
    else
        echo
        echo "Umbra failed to start."
        docker logs "$CONTAINER" 2>&1 || true
        return 1
    fi
}

remove_umbra() {

    if ! container_exists; then
        echo "Umbra container does not exist."
        return
    fi

    echo
    read -r -p "Remove Umbra container? [y/N]: " confirm

    case "$confirm" in

        y|Y|yes|YES)

            docker rm -f "$CONTAINER"

            echo
            echo "Umbra container removed."
            ;;

        *)
            echo "Cancelled."
            ;;

    esac
}

show_logs() {

    if container_exists; then

        echo
        echo "Press CTRL+C to leave logs."
        echo

        docker logs -f "$CONTAINER" || true

    else
        echo "Umbra container does not exist."
    fi
}

menu() {

    if ! docker_ok; then
        echo "Docker is not available."
        exit 1
    fi

    while true; do

        dashboard

        echo
        echo " [1] Refresh dashboard"
        echo " [2] Subscription / inbound paths"
        echo " [3] Container resource usage"
        echo " [4] View live logs"
        echo " [5] Restart Umbra"
        echo " [6] Update Umbra"
        echo " [7] Stop Umbra"
        echo " [8] Start Umbra"
        echo " [9] Remove Umbra container"
        echo " [0] Exit"
        echo

        read -r -p " Select option: " choice

        case "$choice" in

            1)
                ;;

            2)
                show_links
                pause_menu
                ;;

            3)
                clear 2>/dev/null || true
                line
                echo "                 UMBRA RESOURCE USAGE"
                line
                echo
                show_container_stats
                pause_menu
                ;;

            4)
                show_logs
                pause_menu
                ;;

            5)
                restart_umbra
                sleep 2
                ;;

            6)
                update_umbra
                pause_menu
                ;;

            7)
                stop_umbra
                sleep 2
                ;;

            8)
                start_umbra
                sleep 2
                ;;

            9)
                remove_umbra
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
        show_links
        ;;

    stats)
        show_container_stats
        ;;

    logs)
        show_logs
        ;;

    restart)
        restart_umbra
        ;;

    update)
        update_umbra
        ;;

    stop)
        stop_umbra
        ;;

    start)
        start_umbra
        ;;

    *)
        menu
        ;;

esac
UMBRA_MENU

chmod +x "$TMP_MENU"

# =========================================================
# INSTALL UMBRA COMMAND
# =========================================================

if [ "$(id -u)" -eq 0 ]; then

    install -m 0755 "$TMP_MENU" "$MENU_BIN"

elif command -v sudo >/dev/null 2>&1; then

    sudo install -m 0755 "$TMP_MENU" "$MENU_BIN"

else

    die "sudo is required to install the 'umbra' dashboard command."

fi

# =========================================================
# FINISH
# =========================================================

echo
line
echo "                 UMBRA INSTALLATION COMPLETE"
line
echo
echo "Image:"
echo "  $IMAGE"
echo
echo "Container:"
echo "  $CONTAINER"
echo
echo "Port:"
echo "  $HOST_PORT"
echo
echo "Open dashboard anytime with:"
echo
echo "  umbra"
echo
echo "Other commands:"
echo
echo "  umbra status"
echo "  umbra links"
echo "  umbra stats"
echo "  umbra logs"
echo "  umbra restart"
echo "  umbra update"
echo "  umbra stop"
echo "  umbra start"
echo
line
echo

"$MENU_BIN" status
