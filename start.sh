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

# Pane 0: sysinfo app
tmux select-pane -t "$SESSION_NAME":0.0 -T "sysinfo"
tmux send-keys -t "$SESSION_NAME":0.0 \
  "pushd \"${BASEDIR}/${prefix}--desktop-sysinfo\" && chmod +x ./start.sh && exec -a sysinfo bash ./start.sh" C-m

# Split horizontally for collector
tmux split-window -h -t "$SESSION_NAME":0
tmux select-pane -t "$SESSION_NAME":0.1 -T "collector"
tmux send-keys -t "$SESSION_NAME":0.1 \
  "pushd \"${BASEDIR}/${prefix}--collector\" && chmod +x ./start.sh && exec -a collector bash ./start.sh" C-m

# Split vertically for web-app
tmux split-window -v -t "$SESSION_NAME":0.1
tmux select-pane -t "$SESSION_NAME":0.2 -T "web-app"
tmux send-keys -t "$SESSION_NAME":0.2 \
  "pushd \"${BASEDIR}/${prefix}--web-app\" && chmod +x ./start.sh && exec -a web-app bash ./start.sh" C-m

# Split vertically for web-gui
tmux split-window -v -t "$SESSION_NAME":0.2
tmux select-pane -t "$SESSION_NAME":0.3 -T "web-gui"
tmux send-keys -t "$SESSION_NAME":0.3 \
  "pushd \"${BASEDIR}/${prefix}--web-gui\" && chmod +x ./start.sh && exec -a web-gui bash ./start.sh" C-m

# Split vertically for nats subscriber
tmux split-window -v -t "$SESSION_NAME":0.3
tmux select-pane -t "$SESSION_NAME":0.4 -T "nats-sub"
tmux send-keys -t "$SESSION_NAME":0.4 \
  "exec -a nats-sub nats sub desktop-sysinfo" C-m

# Optional: evenly size panes
tmux select-layout -t "$SESSION_NAME":0 tiled

# Attach to the session
tmux attach -t "$SESSION_NAME"
