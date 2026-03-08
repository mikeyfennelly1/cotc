#!/bin/bash

################################################
# SETUP
################################################
OS=$(uname)
if [[ "$OS" == "Darwin" ]]; then
	# OSX uses BSD readlink
	BASEDIR="$(dirname "$0")"
else
	BASEDIR=$(readlink -e "$(dirname "$0")/")
fi
cd "${BASEDIR}"

source "${BASEDIR}"/.env.local
source "${BASEDIR}"/scripts/helpers.sh

prefix="ise--y2--b3--project"

################################################
# START NATS & POSTGRES
################################################
echo "starting NATS"
var_must_exist NATS_PORT
docker compose -f docker-compose.local.yaml up nats -d --wait
echo "NATS is healthy"
echo "starting Postgres"
var_must_exist POSTGRES_PASSWORD POSTGRES_USER POSTGRES_DB POSTGRES_PORT
docker compose -f docker-compose.local.yaml up db -d --wait
echo "Postgres is healthy"

################################################
# START SERVICE SESSIONS
################################################
# Create a new tmux session (or attach if it already exists)
SESSION_NAME="ise--y2--b3--project"

echo "starting TMUX sessions..."

tmux has-session -t "$SESSION_NAME" 2>/dev/null
if [ $? -ne 0 ]; then
  tmux new-session -d -s "$SESSION_NAME"
fi

tmux set-option -t "$SESSION_NAME" pane-border-status top
tmux set-option -t "$SESSION_NAME" pane-border-format "#{?pane_active,#[bg=green fg=black],#[bg=colour238 fg=white]} #{pane_title} #[default]"

start_service() {
  local pane="$SESSION_NAME":0.$1
  local title="$2"
  local dir="${BASEDIR}/${prefix}--$3"
  tmux select-pane -t "$pane" -T "$title"
  tmux send-keys -t "$pane" "pushd \"$dir\" && chmod +x ./start.sh && bash ./start.sh" C-m
}

tmux split-window -h -t "$SESSION_NAME":0
start_service 1 "collector" "collector"

tmux split-window -v -t "$SESSION_NAME":0.1
start_service 2 "web-app" "web-app"

tmux split-window -v -t "$SESSION_NAME":0.2
start_service 3 "web-gui" "web-gui"

start_service 0 "sysinfo" "desktop-sysinfo"

# Optional: evenly size panes
tmux select-layout -t "$SESSION_NAME":0 tiled

# Attach to the session
tmux attach -t "$SESSION_NAME"
