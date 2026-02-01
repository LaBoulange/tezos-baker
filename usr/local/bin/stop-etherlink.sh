#!/bin/bash

# Check if etherlink is running
ETHERLINK_PID=$(ps aux | grep octez-smart-rollup-node | grep -v grep | head -1 | awk '{ print $2 }')

if [ -z "$ETHERLINK_PID" ]; then
    # Etherlink is not running, exit with error
    echo "Etherlink Smart Rollup node is not running or not configured"
    exit 1
fi

# Stop etherlink
kill $ETHERLINK_PID

sleep 1
ps aux | grep octez-smart-rollup-node | grep -v grep

exit 0
