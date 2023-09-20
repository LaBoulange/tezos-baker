#!/bin/bash

kill `ps aux | grep octez-node | head -1 | awk '{ print $2 }'`

sleep 1
ps aux | grep octez | grep -v grep
