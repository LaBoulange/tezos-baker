#####################
# octez installation
#####################

. `which tezos-env.sh`

# Setup ZCASH parameters. This is just needed at initial setup.
mkdir -p "$ZCASH_DIR"
cd "$ZCASH_DIR"

for paramFile in 'sprout-groth16.params' 'sapling-output.params' 'sapling-spend.params'
do
  wget "${ZCASH_DOWNLOAD_URL}/${paramFile}"
  chmod u+rw "$paramFile"
done

# Actual installation of octez
install-octez.sh

#####################
# Setup the RPC node
#####################

mkdir -p "$DATA_DIR"

mkdir "$NODE_RUN_DIR"
mkdir "$NODE_ETC_DIR"

# Initiate the node's configuration file
octez-node config init --config-file=$NODE_CONFIG_FILE --data-dir=$NODE_RUN_DIR --network=mainnet --history-mode=full
octez-node config update --config-file=$NODE_CONFIG_FILE --data-dir=$NODE_RUN_DIR

# Import the latest snapshot from trusted source
wget $NODE_SNAPSHOT_URL
SNAPSHOT=$(basename "$NODE_SNAPSHOT_URL")
octez-node snapshot info $SNAPSHOT
nohup octez-node snapshot import $SNAPSHOT --no-check --config-file=$NODE_CONFIG_FILE --data-dir=$NODE_RUN_DIR &>$NODE_LOG_FILE &
rm $SNAPSHOT

# Start the node
nohup octez-node run --config-file=$NODE_CONFIG_FILE --rpc-addr $NODE_RPC_ADDR --log-output=$NODE_LOG_FILE &>/dev/null &

chmod o-rwx $NODE_RUN_DIR/identity.json

####################
# Sync the RPC node
####################

mkdir $CLIENT_BASE_DIR

octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} bootstrapped 

#########################
# Import your baking key     
#########################

# This step depends on how your keys are stored: Ledger, remote signer or local (not recommended!)
# Please refer to https://opentezos.com/baking/cli-baker/#set-up-using-ppa-with-octez-packages-from-serokell - Step 4 "Import your keys" 
# and to https://opentezos.com/baking/cli-baker/#other-options-for-baking for more details.
# If you're interested in rotating your baking keys without having to change your baking wallet, you might also consider using a consensus key: https://opentezos.com/baking/consensus-key/

# Also, add the public key of the payout account to fund it easily
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} add address $KEY_PAYOUT $TEZPAY_ACCOUNT_HASH

#######################
# Register as delegate  
#######################

octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} register key $KEY_BAKER as delegate

# --> Go to tzkt.io/[your-baker-tz-address] and look under “Delegations” to see if it has been done correctly.
#     It should say something similar to “Registered as baker with 0.xxx XTZ fee”.

# Initialize your stake. "NNN" below should be replaced by the amount of XTZ you wish to stake (absolute min: 600 XTZ, min for baking rights: 6000 XTZ)
INITIAL_STAKE=NNN
octez-client --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} stake $INITIAL_STAKE for $KEY_BAKER

############################
# Start baking and accusing     
############################

nohup octez-baker-${PROTOCOL} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run with local node $NODE_RUN_DIR $KEY_BAKER --liquidity-baking-toggle-vote $BAKER_LIQUIDITY_BAKING_SWITCH &>$BAKER_LOG_FILE &
nohup octez-accuser-${PROTOCOL} --base-dir $CLIENT_BASE_DIR --endpoint http://${NODE_RPC_ADDR} run &>$ACCUSER_LOG_FILE &

##############################################################################################################################
# Start paying: 
# this should only be done once your baker has endorsing rights for the current cycle (you can check that nn TZKT or TZStats)
##############################################################################################################################

mkdir $TEZPAY_RUN_DIR

# Install the Tezpay software
install-tezpay.sh

# Create Tezpay's configuration file
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

# Create Tezpay's payout key file: replace the placeholder below by the unencrypted private key of your payout account.
#
# SECURITY WARNING: The payout account should only hold enough XTZ to pay your delegators. Since this key is stored 
# unencrypted on your machine, an attacker with access to it could withdraw your funds. 
# We strongly recommend using a more secure system, such as a Ledger or a remote signer, as soon as possible. 
# For more information, see https://docs.tez.capital/tezpay/tutorials/how-to-setup/
cat<<EOF>payout_wallet_private.key
edskYYYYYYYYYY: YOUR PAYOUTS ACCOUNT PRIVATE KEY
EOF

chmod go-rwx payout_wallet_private.key

# Run TezPay in continual mode
nohup tezpay continual -p $TEZPAY_RUN_DIR &>$TEZPAY_LOG_FILE &
