#!/bin/bash 

##############################
# Version variables for octez
##############################

GITLAB_PACKAGE_ID='130341215'

export PROTOCOL="PtParisB"
export PROTOCOL_FORMER="Proxford"

export OCTEZ_DOWNLOAD_URL="https://gitlab.com/tezos/tezos/-/package_files/${GITLAB_PACKAGE_ID}/download"
export ZCASH_DOWNLOAD_URL="https://download.z.cash/downloads"

###################################
# Environment variables for TezPay
###################################

export TEZPAY_DOWNLOAD_URL="https://raw.githubusercontent.com/alis-is/tezpay/main/install.sh"
