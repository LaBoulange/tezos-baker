#!/bin/bash 

##############################
# Version variables for octez
##############################

OCTEZ_VERSION="24.1"

#####################################
# Version variables for tezos-baker
#####################################

TEZOS_BAKER_VERSION="${OCTEZ_VERSION}_2"

case "$BAKER_ARCH" in
   "amd64") export BAKER_ARCH='x86_64'; echo "Architecture identifier is '$BAKER_ARCH' (deprecated synonym 'amd64')." ; export BAKER_ARCH='x86_64'
   ;;
   "x86_64" | "arm64") echo "Architecture identifier is '$BAKER_ARCH'"
   ;;
   *) echo "Unknown architecture identifier '$BAKER_ARCH'. Defaulted to 'x86_64'." ; export BAKER_ARCH='x86_64'
   ;;
esac

export OCTEZ_DOWNLOAD_URL="https://octez.tezos.com/releases/octez-v${OCTEZ_VERSION}/binaries/${BAKER_ARCH}/octez-v${OCTEZ_VERSION}.tar.gz"
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
