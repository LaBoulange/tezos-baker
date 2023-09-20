#!/bin/bash 

. `which tezos-env.sh`

nohup tezpay continual -p $TEZPAY_RUN_DIR --disable-donation-prompt &>$TEZPAY_LOG_FILE &

sleep 1
ps aux | grep tezpay | grep -v grep
