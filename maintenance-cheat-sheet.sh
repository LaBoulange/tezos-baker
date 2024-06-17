###################
# Restart / reboot
###################

stop-tezpay.sh
stop-octez.sh

reboot
# You are being disconnected here. Once logged-in again:

start-octez.sh
start-tezpay.sh

# What follows is only relevant in case of ongoing protocol change (see section "Upgrade octez"). 
. `which tezos-env.sh`

BAKER_LOG_FILE_FORMER="/var/log/octez-baker-${PROTOCOL_FORMER}.log"
ACCUSER_LOG_FILE_FORMER="/var/log/octez-accuser-${PROTOCOL_FORMER}.log"

nohup octez-baker-${PROTOCOL_FORMER} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run with local node $NODE_RUN_DIR $KEY_BAKER --liquidity-baking-toggle-vote $BAKER_LIQUIDITY_BAKING_SWITCH &>$BAKER_LOG_FILE_FORMER &
nohup octez-accuser-${PROTOCOL_FORMER} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run &>$ACCUSER_LOG_FILE_FORMER &

################
# Upgrade octez
################

. `which tezos-env.sh`

stop-octez.sh

install-octez.sh

nohup octez-node upgrade storage --config-file=$NODE_CONFIG_FILE --data-dir=$NODE_RUN_DIR &>$NODE_LOG_FILE &
tail -f $NODE_LOG_FILE
# Check whether there is a backup to delete in ~

start-octez.sh

# What follows is only relevant in case of protocol change. 
# During the transition from one protocol to another, both the old and new versions of octez-baker and octez-accuser 
# can operate simultaneously without the risk of a penalty for double operations. 
# Indeed, each of these components only processes blocks corresponding to the protocol version relevant to it. Once the transition
# is completed, the new protocol is the only active one, and the old versions of octez-baker and octez-accuser can be decommissioned.
BAKER_LOG_FILE_FORMER="/var/log/octez-baker-${PROTOCOL_FORMER}.log"
ACCUSER_LOG_FILE_FORMER="/var/log/octez-accuser-${PROTOCOL_FORMER}.log"

nohup octez-baker-${PROTOCOL_FORMER} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run with local node $NODE_RUN_DIR $KEY_BAKER --liquidity-baking-toggle-vote $BAKER_LIQUIDITY_BAKING_SWITCH &>$BAKER_LOG_FILE_FORMER &
nohup octez-accuser-${PROTOCOL_FORMER} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run &>$ACCUSER_LOG_FILE_FORMER &

#####
# Once the protocol transition is completed:
kill # octez-baker-${PROTOCOL_FORMER} pid
kill # octez-accuser-${PROTOCOL_FORMER} pid
rm `find ${INSTALL_DIR} | grep $PROTOCOL_FORMER`
#####

#################
# Upgrade TezPay
#################

stop-tezpay.sh

install-tezpay.sh

start-tezpay.sh

###################
# Stake management
###################

. `which tezos-env.sh`

# Change your staking parameters, LLL being 0 and 5, EEE being between 0 and 1
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} set delegate parameters for $KEY_BAKER --limit-of-staking-over-baking $BAKER_LIMIT_STAKING_OVER_BAKING --edge-of-baking-over-staking $BAKER_EDGE_BAKING_OVER_STAKING
# Increase your staken NNN being the amount of XTZ you wish to stake
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} stake NNN for $KEY_BAKER
# Decrease your stake, NNN being the amount of XTZ you wish to unstake (takes 2 cycles)
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} unstake NNN for $KEY_BAKER
# Finalize the unstaked balance (only after 4 cycles)
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} finalize unstake for $KEY_BAKER
# Feed the payouts account from the baker account, NNN being a spendable amount
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} transfer NNN from $KEY_BAKER to $KEY_PAYOUT

#################
# Voting process
#################

. `which tezos-env.sh`

octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} show voting period
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} submit proposals for $KEY_BAKER <proposal1> <proposal2> ...
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} submit ballot for $KEY_BAKER <proposal> <yay|nay|pass>
