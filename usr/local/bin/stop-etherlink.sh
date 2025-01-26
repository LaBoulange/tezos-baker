#!/bin/bash

kill `ps aux | grep octez-smart-rollup-node | head -1 | awk '{ print $2 }'`

sleep 1
ps aux | grep octez-smart-rollup-node | grep -v grep
