#!/bin/bash

HOST="api.cotc.local"
HOSTS_FILE="/etc/hosts"

# Get the minikube IP
IP=$(minikube ip 2>/dev/null)

if [ -z "$IP" ]; then
  echo "Could not determine minikube IP. Is minikube running?"
  exit 1
fi

# Remove any existing entry for this host
sudo sed -i "/$HOST/d" "$HOSTS_FILE"

# Add the new entry
echo "$IP  $HOST" | sudo tee -a "$HOSTS_FILE" > /dev/null

echo "Added: $IP  $HOST"
