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
