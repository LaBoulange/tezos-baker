#!/bin/bash 

. `which tezos-env.sh`

INSTALL_USER=`whoami`
INSTALL_GROUP=`groups | awk '{print $1}'`

TEZPAY_EXECUTABLE="tezpay"
PAYOUT_FIXER_EXECUTABLE="tezpay-payout-fixer"
PAYOUTS_SUBSTITUTOR_EXECUTABLE="payouts-substitutor"


cd $TEZPAY_RUN_DIR

wget -q $TEZPAY_DOWNLOAD_URL -O $TEZPAY_INSTALL_SCRIPT
sh $TEZPAY_INSTALL_SCRIPT
rm $TEZPAY_INSTALL_SCRIPT

chown $INSTALL_USER:$INSTALL_GROUP $TEZPAY_EXECUTABLE
chmod u+rwx $TEZPAY_EXECUTABLE
chmod go-rwx $TEZPAY_EXECUTABLE
mv $TEZPAY_EXECUTABLE $INSTALL_DIR

wget -q $TEZPAY_PAYOUT_FIXER_DOWNLOAD_URL -O $PAYOUT_FIXER_EXECUTABLE
chown $INSTALL_USER:$INSTALL_GROUP $PAYOUT_FIXER_EXECUTABLE
chmod u+rwx $PAYOUT_FIXER_EXECUTABLE
chmod go-rwx $PAYOUT_FIXER_EXECUTABLE
mv $PAYOUT_FIXER_EXECUTABLE $INSTALL_DIR

wget -q $TEZPAY_PAYOUTS_SUBSTITUTOR_DOWNLOAD_URL -O $PAYOUTS_SUBSTITUTOR_EXECUTABLE
chown $INSTALL_USER:$INSTALL_GROUP $PAYOUTS_SUBSTITUTOR_EXECUTABLE
chmod u+rwx $PAYOUTS_SUBSTITUTOR_EXECUTABLE
chmod go-rwx $PAYOUTS_SUBSTITUTOR_EXECUTABLE
mv $PAYOUTS_SUBSTITUTOR_EXECUTABLE $INSTALL_DIR
