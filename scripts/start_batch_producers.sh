#!/bin/bash

BASE_PORT=8081
GROUP="test.batch"

echo "Creating group: ${GROUP}"
cotc mkgroup -n "${GROUP}"

for i in $(seq 1 100); do
  NAME="batch-test--${i}"
  PORT=$((BASE_PORT + i - 1))
  if cotc mkproducer -n "${NAME}" -g "${GROUP}"; then
    cotc produce -n "${NAME}" -t sysinfo --listen_port=${PORT} --log-level=debug --publishing_interval_sec=1 &
    echo "Started producer: ${NAME} on port ${PORT}"
  else
    echo "Failed to register producer: ${NAME}, skipping"
  fi
done
