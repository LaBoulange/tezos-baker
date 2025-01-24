#!/bin/bash 

##############################
# Version variables for octez
##############################

case "$BAKER_ARCH" in
   "amd64") GITLAB_PACKAGE_ID='171290689'
   ;;
   "arm64") GITLAB_PACKAGE_ID='171291496'
   ;;
   *) echo "Unknown architecture '$BAKER_ARCH'. Assumed 'amd64'." ; GITLAB_PACKAGE_ID='171290689'
   ;;
esac

export PROTOCOL="PsQuebec" 
export PROTOCOL_FORMER="PsParisC"

export OCTEZ_DOWNLOAD_URL="https://gitlab.com/tezos/tezos/-/package_files/${GITLAB_PACKAGE_ID}/download"
export ZCASH_DOWNLOAD_URL="https://download.z.cash/downloads"

##############################
# Version variables for TezPay
##############################

export TEZPAY_DOWNLOAD_URL="https://raw.githubusercontent.com/alis-is/tezpay/main/install.sh"
export TEZPAY_PAYOUT_FIXER_DOWNLOAD_URL="https://github.com/tez-capital/tezpay/releases/latest/download/tezpay-payout-fixer-linux-${BAKER_ARCH}"
export TEZPAY_PAYOUTS_SUBSTITUTOR_DOWNLOAD_URL="https://github.com/LaBoulange/tezpay-extensions/releases/latest/download/payouts-substitutor-linux-${BAKER_ARCH}"
