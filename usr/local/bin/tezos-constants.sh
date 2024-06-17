#!/bin/bash 

##############################
# Version variables for octez
##############################

case "$BAKER_ARCH" in
   "amd64") GITLAB_PACKAGE_ID='130341215'
   ;;
   "arm64") GITLAB_PACKAGE_ID='130343985' 
   ;;
   *) echo "Unknown architecture '$BAKER_ARCH'. Assumed 'amd64'." ; GITLAB_PACKAGE_ID='130341215'
   ;;
esac

export PROTOCOL="PtParisB"
export PROTOCOL_FORMER="Proxford"

export OCTEZ_DOWNLOAD_URL="https://gitlab.com/tezos/tezos/-/package_files/${GITLAB_PACKAGE_ID}/download"
export ZCASH_DOWNLOAD_URL="https://download.z.cash/downloads"

###################################
# Environment variables for TezPay
###################################

PAYOUTS_SUBSTITUTOR_VERSION="0.1"

export TEZPAY_DOWNLOAD_URL="https://raw.githubusercontent.com/alis-is/tezpay/main/install.sh"
export TEZPAY_PAYOUTS_SUBSTITUTOR_DOWNLOAD_URL="https://github.com/LaBoulange/tezpay-extensions/releases/download/${PAYOUTS_SUBSTITUTOR_VERSION}/payouts-substitutor-linux-${BAKER_ARCH}"
