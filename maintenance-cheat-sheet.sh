###################
# Restart / reboot
###################

stop-tezpay.sh # Only if you configured Tezpay to pay your delegators
stop-etherlink.sh # Only if you configured the Etherlink Smart Rollup node
stop-octez.sh

reboot
# You are being disconnected here. Once logged-in again:

start-octez.sh
start-etherlink.sh # Only if you configured the Etherlink Smart Rollup node
start-tezpay.sh # Only if you configured Tezpay to pay your delegators

# What follows is only relevant in case of ongoing protocol change (see section "Upgrade octez"). 
. `which tezos-env.sh`

BAKER_LOG_FILE_FORMER="/var/log/octez-baker-${PROTOCOL_FORMER}.log"
ACCUSER_LOG_FILE_FORMER="/var/log/octez-accuser-${PROTOCOL_FORMER}.log"

nohup octez-baker-${PROTOCOL_FORMER} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run with local node $NODE_RUN_DIR $KEY_BAKER --liquidity-baking-toggle-vote $BAKER_LIQUIDITY_BAKING_SWITCH &>$BAKER_LOG_FILE_FORMER &
nohup octez-accuser-${PROTOCOL_FORMER} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run &>$ACCUSER_LOG_FILE_FORMER &

################
# Upgrade octez
################

install-tezos-baker.sh

. `which tezos-env.sh`

stop-tezpay.sh # Only if you configured Tezpay to pay your delegators
stop-etherlink.sh # Only if you configured the Etherlink Smart Rollup node
stop-octez.sh

install-octez.sh

# It is no problem to run the command below unconditionally. If not needed, it will do nothing.
nohup octez-node upgrade storage --config-file=$NODE_CONFIG_FILE --data-dir=$NODE_RUN_DIR &>$NODE_LOG_FILE &
tail -f $NODE_LOG_FILE
# Check whether there is a backup to move or delete in your ~ directory 

start-octez.sh
start-etherlink.sh # Only if you configured the Etherlink Smart Rollup node
start-tezpay.sh # Only if you configured Tezpay to pay your delegators

# What follows is only relevant in case of protocol change. 
# During the transition from one protocol to another, both the old and new versions of octez-baker and octez-accuser 
# can operate simultaneously without the risk of a penalty for double operations. 
# Indeed, each of these components only processes blocks corresponding to the protocol version relevant to it. Once the transition
# is completed, the new protocol is the only active one, and the old versions of octez-baker and octez-accuser can be decommissioned.
BAKER_LOG_FILE_FORMER="/var/log/octez-baker-${PROTOCOL_FORMER}.log"
ACCUSER_LOG_FILE_FORMER="/var/log/octez-accuser-${PROTOCOL_FORMER}.log"

nohup octez-baker-${PROTOCOL_FORMER} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run with local node $NODE_RUN_DIR $KEY_BAKER --liquidity-baking-toggle-vote $BAKER_LIQUIDITY_BAKING_SWITCH --dal-node http://${DAL_ENDPOINT_ADDR} &>$BAKER_LOG_FILE_FORMER &
nohup octez-accuser-${PROTOCOL_FORMER} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run &>$ACCUSER_LOG_FILE_FORMER &

#####
# Once the protocol transition is completed:
kill # octez-baker-${PROTOCOL_FORMER} pid
kill # octez-accuser-${PROTOCOL_FORMER} pid
rm `find ${INSTALL_DIR} | grep $PROTOCOL_FORMER`
#####

#######################################################################
# Upgrade TezPay (only if you configured Tezpay to pay your delegators)
#######################################################################

stop-tezpay.sh

install-tezpay.sh

start-tezpay.sh

###################
# Stake management
###################

. `which tezos-env.sh`

# Change your external staking parameters, after having modified $BAKER_LIMIT_STAKING_OVER_BAKING and/or $BAKER_EDGE_BAKING_OVER_STAKING
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} set delegate parameters for $KEY_BAKER --limit-of-staking-over-baking $BAKER_LIMIT_STAKING_OVER_BAKING --edge-of-baking-over-staking $BAKER_EDGE_BAKING_OVER_STAKING
# Increase your own stake, NNN below being the amount of XTZ you wish to stake
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} stake NNN for $KEY_BAKER
# Decrease your own stake, NNN below being the amount of XTZ you wish to unstake (takes 2 cycles)
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} unstake NNN for $KEY_BAKER
# Finalize your unstaked balance (only after 4 cycles)
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} finalize unstake for $KEY_BAKER
# If you configured Tezpay to pay your delegators, feed the payouts account from the baker account, NNN below being a spendable amount
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} transfer NNN from $KEY_BAKER to $KEY_PAYOUT

#################
# Voting process
#################

. `which tezos-env.sh`

# Show the details of the current voting period (see https://tezos.gitlab.io/active/voting.html#periods)
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} show voting period
# Vote for a proposal to be further explored (proposal period only)
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} submit proposals for $KEY_BAKER <proposal1> <proposal2> ...
# Vote 'yay', 'nay' or 'pass' for a proposal (exploration and promotion periods only)
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} submit ballot for $KEY_BAKER <proposal> <yay|nay|pass>

############################################
# Switch history mode from full to rolling #
############################################

# Set the NODE_MODE environment variable of your BAKER_INSTALLATION_DIR/tezos-env.sh file to "rolling", or "rolling:<number_of_additional_cycles>"
# (see https://tezos.gitlab.io/user/history_modes.html for details) 

. `which tezos-env.sh`
octez-node config update --config-file=$NODE_CONFIG_FILE --data-dir=$NODE_RUN_DIR --history-mode=$NODE_MODE

stop-octez.sh
nohup octez-node run --force-history-mode-switch --config-file=$NODE_CONFIG_FILE --rpc-addr $NODE_RPC_ADDR --log-output=$NODE_LOG_FILE &>/dev/null &

octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} bootstrapped
nohup octez-baker-${PROTOCOL} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run with local node $NODE_RUN_DIR $KEY_BAKER --liquidity-baking-toggle-vote $BAKER_LIQUIDITY_BAKING_SWITCH &>$BAKER_LOG_FILE &
nohup octez-accuser-${PROTOCOL} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run &>$ACCUSER_LOG_FILE &
