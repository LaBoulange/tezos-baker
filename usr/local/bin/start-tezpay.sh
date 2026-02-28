#!/bin/bash 

. `which tezos-env.sh`

# Check if TezPay is configured
if [ ! -d "$TEZPAY_RUN_DIR" ]; then
    echo "TezPay is not configured. Run 'tezos-baker setup' or configure TezPay manually."
    exit 1
fi

# Check if tezpay executable exists
if ! command -v tezpay &> /dev/null; then
    echo "TezPay executable not found. Please install TezPay first."
    exit 1
fi

nohup tezpay continual -p $TEZPAY_RUN_DIR --include-previous-cycles $TEZPAY_INTERVAL --interval $TEZPAY_INTERVAL --disable-donation-prompt &>$TEZPAY_LOG_FILE &

sleep 1
ps aux | grep tezpay | grep -v grep

exit 0
