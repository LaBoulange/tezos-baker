#!/bin/bash

. `which tezos-env.sh`

nohup octez-smart-rollup-node --endpoint "http://${NODE_RPC_ADDR}" run --data-dir $ETHERLINK_RUN_DIR  &>$ETHERLINK_NODE_LOG_FILE &

# Check the Smart Rollup node state
curl $ETHERLINK_RPC_ADDR/health
