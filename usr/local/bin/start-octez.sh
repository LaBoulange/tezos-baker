#!/bin/bash

. `which tezos-env.sh`

rm $NODE_LOG_FILE

echo "Starting RPC node"
nohup octez-node run --config-file=$NODE_CONFIG_FILE --rpc-addr $NODE_RPC_ADDR --log-output=$NODE_LOG_FILE &>/dev/null &

echo "Checking RPC node bootstrap"
sleep 20
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} bootstrapped

echo "Starting DAL node"
nohup octez-dal-node run &>$DAL_LOG_FILE &

echo "Checking DAL node bootstrap"
sleep 5
curl http://localhost:10732/p2p/points/info?connected

echo "Starting baker"
nohup octez-baker-${PROTOCOL} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run with local node $NODE_RUN_DIR $KEY_BAKER --liquidity-baking-toggle-vote $BAKER_LIQUIDITY_BAKING_SWITCH --dal-node http://${DAL_ENDPOINT_ADDR} &>$BAKER_LOG_FILE &

echo "Starting accuser"
nohup octez-accuser-${PROTOCOL} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run &>$ACCUSER_LOG_FILE &

sleep 1
ps aux | grep octez | grep -v grep
