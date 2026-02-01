#!/bin/bash

# Check if tezpay is running
TEZPAY_PID=$(ps aux | grep tezpay | grep -v grep | head -1 | awk '{ print $2 }')

if [ -z "$TEZPAY_PID" ]; then
    # TezPay is not running, exit with error
    echo "TezPay is not running or not configured"
    exit 1
fi

# Stop tezpay
kill $TEZPAY_PID

sleep 1
ps aux | grep tezpay | grep -v grep

exit 0
