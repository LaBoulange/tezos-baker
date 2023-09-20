#!/bin/bash

kill `ps aux | grep tezpay | head -1 | awk '{ print $2 }'`

sleep 1
ps aux | grep tezpay | grep -v grep
