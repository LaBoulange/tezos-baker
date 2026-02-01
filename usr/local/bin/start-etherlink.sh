#!/bin/bash

. `which tezos-env.sh`

# Check if Etherlink is configured
if [ ! -d "$ETHERLINK_RUN_DIR" ]; then
    echo "Etherlink Smart Rollup node is not configured. Run 'tezos-baker setup' or configure Etherlink manually."
    exit 1
fi

# Check if octez-smart-rollup-node executable exists
if ! command -v octez-smart-rollup-node &> /dev/null; then
    echo "octez-smart-rollup-node executable not found. Please install Octez first."
    exit 1
fi

nohup octez-smart-rollup-node --endpoint "http://${NODE_RPC_ADDR}" run --data-dir $ETHERLINK_RUN_DIR  &>$ETHERLINK_NODE_LOG_FILE &

# Check the Smart Rollup node state
sleep 5
curl $ETHERLINK_RPC_ADDR/health

exit 0
