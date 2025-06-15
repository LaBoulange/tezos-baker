#!/bin/bash 

##############################
# Version variables for octez
##############################

case "$BAKER_ARCH" in
   "amd64") GITLAB_PACKAGE_ID='200923183'
   ;;
   "arm64") GITLAB_PACKAGE_ID='200925067'
   ;;
   *) echo "Unknown architecture '$BAKER_ARCH'. Assumed 'amd64'." ; GITLAB_PACKAGE_ID='200923183'
   ;;
esac

export PROTOCOL="PsRiotum" 
export PROTOCOL_FORMER="PsRiotum"

export OCTEZ_DOWNLOAD_URL="https://gitlab.com/tezos/tezos/-/package_files/${GITLAB_PACKAGE_ID}/download"
export ZCASH_DOWNLOAD_URL="https://download.z.cash/downloads"

###############################
# Version variables for TezPay
###############################

export TEZPAY_DOWNLOAD_URL="https://raw.githubusercontent.com/alis-is/tezpay/main/install.sh"

####################################################
# Version variables for Etherlink Smart Rollup node
####################################################

export ETHERLINK_ROLLUP_ADDR_MAINNET="sr1Ghq66tYK9y3r8CC1Tf8i8m5nxh8nTvZEf"
export ETHERLINK_ROLLUP_ADDR_GHOSTNET="sr18wx6ezkeRjt1SZSeZ2UQzQN3Uc3YLMLqg"
