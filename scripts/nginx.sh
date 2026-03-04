#!/usr/bin/env bash

set -e

# --------------------------------------------------
# Configurable values
# --------------------------------------------------
NGINX_BIN=${NGINX_BIN:-nginx}
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)/.."
TEMPLATE_FILE="$PROJECT_DIR/nginx.conf"
PREFIX="$PROJECT_DIR"
CONFIG_FILE="$PREFIX/nginx-local.conf"
PID_FILE="$PREFIX/nginx.pid"
LOG_DIR="$PREFIX/logs"

# --------------------------------------------------
# Utility functions
# --------------------------------------------------

function ensure_dirs() {
    mkdir -p "$LOG_DIR"
}

function generate_config() {
    # Load .env
    if [ -f "$PROJECT_DIR/.env" ]; then
        set -a
        # shellcheck disable=SC1091
        source "$PROJECT_DIR/.env"
        set +a
    fi

    export NGINX_PORT="${NGINX_PORT:-8080}"
    export NGINX_SERVER_NAME="${NGINX_SERVER_NAME:-localhost}"
    export UPSTREAM_HOST="${UPSTREAM_HOST:-localhost}"
    export UPSTREAM_PORT="${WEB_APP_PORT:-8082}"
    export UPSTREAM_PORT="${COLLECTOR_LISTEN_PORT:-8081}"

    local server_block
    server_block=$(envsubst '${NGINX_PORT} ${NGINX_SERVER_NAME} ${UPSTREAM_HOST} ${UPSTREAM_PORT} ${WEB_APP_PORT} ${COLLECTOR_LISTEN_PORT}' < "$TEMPLATE_FILE")

    cat > "$CONFIG_FILE" <<EOF
daemon off;
error_log /dev/stderr warn;

events {}

http {
    access_log /dev/stdout;
$server_block
}
EOF
}

function check_nginx_installed() {
    if ! command -v $NGINX_BIN >/dev/null 2>&1; then
        echo "ERROR: nginx not found. Install it first."
        exit 1
    fi
}

function validate_config() {
    echo "Validating nginx config..."
    $NGINX_BIN -t -c "$CONFIG_FILE" -p "$PREFIX"
}

function is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# --------------------------------------------------
# Commands
# --------------------------------------------------

function start() {
    check_nginx_installed
    ensure_dirs
    generate_config
    validate_config

    if is_running; then
        echo "Nginx already running (PID $(cat $PID_FILE))"
        exit 0
    fi

    echo "Starting nginx (logs streaming below)..."
    $NGINX_BIN -c "$CONFIG_FILE" -p "$PREFIX"
}

function stop() {
    if is_running; then
        echo "Stopping nginx..."
        $NGINX_BIN -s stop -c "$CONFIG_FILE" -p "$PREFIX"
        rm -f "$PID_FILE"
        echo "Stopped."
    else
        echo "Nginx is not running."
    fi
}

function reload() {
    if is_running; then
        generate_config
        validate_config
        echo "Reloading nginx..."
        $NGINX_BIN -s reload -c "$CONFIG_FILE" -p "$PREFIX"
        echo "Reloaded."
    else
        echo "Nginx is not running."
        exit 1
    fi
}

function restart() {
    stop
    sleep 1
    start
}

function status() {
    if is_running; then
        echo "Nginx is running (PID $(cat $PID_FILE))"
    else
        echo "Nginx is NOT running"
    fi
}

# --------------------------------------------------
# Entry
# --------------------------------------------------

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    reload)
        reload
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|reload|restart|status}"
        exit 1
        ;;
esac
