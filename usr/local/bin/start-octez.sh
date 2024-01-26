#!/bin/bash

. `which tezos-env.sh`

rm $NODE_LOG_FILE

echo "Starting node"
nohup octez-node run --config-file=$NODE_CONFIG_FILE --rpc-addr $NODE_RPC_ADDR --log-output=$NODE_LOG_FILE &>/dev/null &
sleep 15

echo "Checking bootstrap"
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} bootstrapped

echo "Starting baker"
nohup octez-baker-${PROTOCOL} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run with local node $NODE_RUN_DIR $KEY_BAKER --liquidity-baking-toggle-vote $BAKER_LIQUIDITY_BAKING_SWITCH --adaptive-issuance-vote $BAKER_ADAPTIVE_ISSUANCE_SWITCH &>$BAKER_LOG_FILE &

echo "Starting accuser"
nohup octez-accuser-${PROTOCOL} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run &>$ACCUSER_LOG_FILE &

sleep 1
ps aux | grep octez | grep -v grep
