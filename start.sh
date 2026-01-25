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

source "${BASEDIR}"/.env
source "${BASEDIR}"/scripts/helpers.sh

prefix="ise--y2--b3--project"

################################################
# START NATS & POSTGRES
################################################
# start NATS and Postgres
echo "starting NATS"
docker compose up nats -d
echo "starting Postgres"
docker compose up db -d

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

# Pane 0: sysinfo app
tmux send-keys -t "$SESSION_NAME":0.0 \
  "pushd \"${BASEDIR}/${prefix}--desktop-sysinfo\" && chmod +x ./start.sh && ./start.sh; popd" C-m

# Split horizontally for collector
tmux split-window -h -t "$SESSION_NAME":0
tmux send-keys -t "$SESSION_NAME":0.1 \
  "pushd \"${BASEDIR}/${prefix}--collector\" && chmod +x ./start.sh && ./start.sh; popd" C-m

# Split vertically for web-app
tmux split-window -v -t "$SESSION_NAME":0.1
tmux send-keys -t "$SESSION_NAME":0.2 \
  "pushd \"${BASEDIR}/${prefix}--web-app\" && chmod +x ./start.sh && ./start.sh; popd" C-m

# Split vertically for nats subscriber
tmux split-window -v -t "$SESSION_NAME":0.2
tmux send-keys -t "$SESSION_NAME":0.3 \
  "nats sub desktop-sysinfo" C-m

# Optional: evenly size panes
tmux select-layout -t "$SESSION_NAME":0 tiled

# Attach to the session
tmux attach -t "$SESSION_NAME"
