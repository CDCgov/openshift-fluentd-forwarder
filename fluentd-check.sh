#!/bin/bash

# test that something is listening on the fluentd secure_forward port
RESULT=`ss -tnlp 2>/dev/null | grep 24284`

# if no port is running, fail
if [ "" == "${RESULT}" ]; then
    exit 1
fi

# otherwise explicit clean exit
exit 0