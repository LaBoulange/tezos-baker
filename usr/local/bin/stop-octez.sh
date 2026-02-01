#!/bin/bash

# Stop octez-dal-node
DAL_PID=$(ps aux | grep octez-dal-node | grep -v grep | head -1 | awk '{ print $2 }')
if [ -n "$DAL_PID" ]; then
    kill $DAL_PID
fi

# Stop octez-baker
BAKER_PID=$(ps aux | grep octez-baker | grep -v grep | head -1 | awk '{ print $2 }')
if [ -n "$BAKER_PID" ]; then
    kill $BAKER_PID
fi

# Stop octez-accuser
ACCUSER_PID=$(ps aux | grep octez-accuser | grep -v grep | head -1 | awk '{ print $2 }')
if [ -n "$ACCUSER_PID" ]; then
    kill $ACCUSER_PID
fi

# Stop octez-node
NODE_PID=$(ps aux | grep octez-node | grep -v grep | head -1 | awk '{ print $2 }')
if [ -n "$NODE_PID" ]; then
    kill $NODE_PID
fi

sleep 1
ps aux | grep octez | grep -v grep

exit 0
