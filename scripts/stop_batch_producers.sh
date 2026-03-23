#!/bin/bash

GROUP="test.batch"

echo "Killing all batch producer processes..."
pkill -f "cotc produce -n batch-test--" && echo "Processes killed." || echo "No matching processes found."

echo "Deleting producers from group: ${GROUP}"
for i in $(seq 1 100); do
  NAME="batch-test--${i}"
  cotc rmproducer -n "${NAME}" 2>/dev/null && echo "Removed producer: ${NAME}"
done

echo "Deleting group: ${GROUP}"
cotc rmgroup -n "${GROUP}"
