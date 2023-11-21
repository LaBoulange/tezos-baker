#!/bin/bash 

##################################
# Environment variables for octez
##################################

export PROTOCOL="PtNairob"
export PROTOCOL_VERSION="18.1-1"

export OCTEZ_DOWNLOAD_URL="https://github.com/serokell/tezos-packaging/releases/download/v${PROTOCOL_VERSION}/binaries-${PROTOCOL_VERSION}.tar.gz"
export ZCASH_DOWNLOAD_URL="https://download.z.cash/downloads"
export ZCASH_DIR="${HOME}/.zcash-params"
export BUILD_DIR='/tmp/build-octez'
export INSTALL_DIR="/usr/local/bin"
export DATA_DIR="/var/tezos"

export NODE_ETC_DIR="/usr/local/etc/octez-node"
export NODE_RUN_DIR="${DATA_DIR}/octez-node"
export NODE_LOG_FILE="/var/log/octez-node.log"
export NODE_CONFIG_FILE="${NODE_ETC_DIR}/config.json"
export NODE_RPC_ADDR="127.0.0.1:8732"
export NODE_SNAPSHOT_URL="https://lambsonacid-octez.s3.us-east-2.amazonaws.com/mainnet/full/tezos.snapshot"

export KEY_BAKER="YOUR BAKER ALIAS. Example: bob"
export KEY_PAYOUT="${KEY_BAKER}-payouts"

export CLIENT_BASE_DIR="${DATA_DIR}/octez-client"
export CLIENT_LOG_FILE="/var/log/octez-client.log"

export BAKER_ACCOUNT_HASH="tzXXXXXXXXXX: YOUR BAKER ADDRESS HASH"
export BAKER_LOG_FILE="/var/log/octez-baker.log"
export BAKER_LIQUIDITY_BAKING_SWITCH="pass"

export ACCUSER_LOG_FILE="/var/log/octez-accuser.log"

###################################
# Environment variables for TezPay
###################################

export TEZPAY_RUN_DIR="${DATA_DIR}/tezpay"
export TEZPAY_DOWNLOAD_URL="https://raw.githubusercontent.com/alis-is/tezpay/main/install.sh"
export TEZPAY_INSTALL_SCRIPT="/tmp/install.sh"
export TEZPAY_ACCOUNT_HASH="tzYYYYYYYYYY: YOUR PAYOUTS ADDRESS HASH"
export TEZPAY_FEES=0.1
export TEZPAY_LOG_FILE="/var/log/tezpay.log"

