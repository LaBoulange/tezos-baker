#!/bin/bash 

##############################
# Version variables for octez
##############################

export PROTOCOL="PtParisB"
export PROTOCOL_VERSION="20.0-1"
export PROTOCOL_FORMER="Proxford"

export OCTEZ_DOWNLOAD_URL="https://github.com/serokell/tezos-packaging/releases/download/v${PROTOCOL_VERSION}/binaries-${PROTOCOL_VERSION}.tar.gz"
export ZCASH_DOWNLOAD_URL="https://download.z.cash/downloads"

###################################
# Environment variables for TezPay
###################################

export TEZPAY_DOWNLOAD_URL="https://raw.githubusercontent.com/alis-is/tezpay/main/install.sh"
