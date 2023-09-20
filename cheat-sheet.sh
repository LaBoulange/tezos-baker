################
# Initial setup
################

. `which tezos-env.sh`

# Setup ZCASH parameters
ZCASH=$(basename "$ZCASH_DOWNLOAD_URL")

mkdir $BUILD_DIR
cd $BUILD_DIR

wget $ZCASH_DOWNLOAD_URL
chmod u+x $ZCASH
./${ZCASH}

cd /
rm -rf $BUILD_DIR

install-octez.sh

#####################
# Setup the RPC node
#####################

mkdir $DATA_DIR

mkdir $NODE_RUN_DIR
mkdir $NODE_ETC_DIR

octez-node config init --config-file=$NODE_CONFIG_FILE --data-dir=$NODE_RUN_DIR --network=mainnet --history-mode=full
octez-node config update --config-file=$NODE_CONFIG_FILE --data-dir=$NODE_RUN_DIR

# Import the latest snapshot from trusted source
wget $NODE_SNAPSHOT_URL
SNAPSHOT=$(basename "$NODE_SNAPSHOT_URL")
octez-node snapshot info $SNAPSHOT
nohup octez-node snapshot import $SNAPSHOT --no-check --config-file=$NODE_CONFIG_FILE --data-dir=$NODE_RUN_DIR &>$NODE_LOG_FILE &
rm $SNAPSHOT

# Starts the node
nohup octez-node run --config-file=$NODE_CONFIG_FILE --rpc-addr $NODE_RPC_ADDR --log-output=$NODE_LOG_FILE &>/dev/null &

chmod o-rwx $NODE_RUN_DIR/identity.json

####################
# Sync the RPC node
####################

mkdir $CLIENT_BASE_DIR

octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} bootstrapped 

##############
# Import keys     
##############

# Depends on how your keys are stored: Ledger, remote signer or local (not recommended!)

#######################
# Register as delegate  
#######################

octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} register key $KEY_BAKER as delegate

# --> Go to tzkt.io/[your-baker-tz-address] and look under “Delegations” to see if it has been done correctly.
#     It should say something similar to “Registered as baker with 0.00035 XTZ fee”.

############################
# Start baking and accusing     
############################

nohup octez-baker-${PROTOCOL} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run with local node $NODE_RUN_DIR $KEY_BAKER --liquidity-baking-toggle-vote $BAKER_VOTE_SWITCH &>$BAKER_LOG_FILE &
nohup octez-accuser-${PROTOCOL} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run &>$ACCUSER_LOG_FILE &

#############################################################################################################################################
# Start paying : this should only be done once your baker has endorsing rights for the current cycle (you can check that nn TZKT or TZStats)
#############################################################################################################################################

mkdir $TEZPAY_RUN_DIR

install-tezpay.sh

cat<<EOF>config.hjson
{
  tezpay_config_version: 0
  disable_analytics: false
  baker: "${BAKER_ACCOUNT_HASH}"
  payouts: {
    wallet_mode: local-private-key
    payout_mode: actual
    fee: $TEZPAY_FEES
    baker_pays_transaction_fee: true
    baker_pays_allocation_fee: true
    minimum_payout_amount: 0.00
  }
  delegators: {
    requirements: {
      minimum_balance: 0
    }
    overrides: {
      ${TEZPAY_ACCOUNT_HASH}: {
        fee: 1.0
      }
    }
  }
  network: {
    rpc_url: http://${NODE_RPC_ADDR}/
    tzkt_url: https://api.tzkt.io/
    explorer: https://tzstats.com/
    ignore_kt: false
  }
  overdelegation: {
    protect: true
  }
}
EOF

cat<<EOF>payout_wallet_private.key
$TEZPAY_ACCOUNT_PRIVATE_KEY
EOF

chmod go-rwx payout_wallet_private.key

nohup tezpay continual -p $TEZPAY_RUN_DIR &>$TEZPAY_LOG_FILE &

###################
# Restart / reboot
###################

stop-tezpay.sh
stop-octez.sh

reboot
# You are being disconnected here. Once logged-in again:

start-octez.sh
start-tezpay.sh

################
# Upgrade octez
################

stop-octez.sh

install-octez.sh

nohup octez-node upgrade storage --config-file=$NODE_CONFIG_FILE --data-dir=$NODE_RUN_DIR &>$NODE_LOG_FILE &
tail -f $NODE_LOG_FILE
# Check whether there is a backup to delete in ~

start-octez.sh

# What follows is only relevant in case of protocol change:
PROTOCOL_FORMER="PtMumbai"
BAKER_LOG_FILE_FORMER="/var/log/octez-baker-${PROTOCOL_FORMER}.log"
ACCUSER_LOG_FILE_FORMER="/var/log/octez-accuser-${PROTOCOL_FORMER}.log"

nohup octez-baker-${PROTOCOL_FORMER} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run with local node $NODE_RUN_DIR $KEY_BAKER --liquidity-baking-toggle-vote $BAKER_VOTE_SWITCH &>$BAKER_LOG_FILE_FORMER &
nohup octez-accuser-${PROTOCOL_FORMER} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run &>$ACCUSER_LOG_FILE_FORMER &

#####
# Once the protocol switch is actually done on chain
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

# Adjust the deposits limit, NNN being an amount
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} set deposits limit for $KEY_BAKER to NNN  
# Feed the payouts account from the baker account, NNN being an amount
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} transfer NNN from $KEY_BAKER to $KEY_PAYOUT

#################
# Voting process
#################

octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} show voting period
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} submit proposals for $KEY_BAKER <proposal1> <proposal2> ...
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} submit ballot for $KEY_BAKER <proposal> <yay|nay|pass>
