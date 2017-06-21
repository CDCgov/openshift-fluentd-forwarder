#!/bin/bash

# set up user id into passwd wrapper
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
cat passwd.template | envsubst > /tmp/passwd
export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/etc/group
USER_NAME=$(id -un)

# show that alternate user IDs are being honored
echo "Running fluentd as user ${USER_NAME} (${USER_ID})"

# copy openshift configmap templte if avaiable, otherwise use built-in template
if [ -f /tmp/fluentd-config/fluentd.conf ]; then
    echo "Using OpenShift ConfigMap configuration"
    cat /tmp/fluentd-config/fluentd.conf | envsubst > /etc/fluent/fluentd.conf
else 
    echo "Using Docker image configuration"
    cat ~/fluentd.conf.template | envsubst > /etc/fluent/fluentd.conf
fi

ADDITIONAL_OPTS=""
# set additional options if TARGET_TYPE is splunk_ex
if [ "splunk_ex" == "${TARGET_TYPE}" ]; then
    ADDITIONAL_OPTS="output_format json"
fi
export ADDITIONAL_OPTS

# set base args to point to fluentd.conf
fluentdargs="-c /etc/fluent/fluentd.conf"

# if verbose then set output to be verbose and print configuration before it is loaded
if [[ $VERBOSE ]]; then
	echo "Using Raw Configuration: "
	cat /etc/fluent/fluentd.conf

	set -ex
	fluentdargs="-vv ${fluentdargs}"
else
  	set -e
fi

# set up IPADDR for fluentd - from OpenShift/Origin logging-fluentd
IPADDR4=`/usr/sbin/ip -4 addr show dev eth0 | grep inet | sed -e "s/[ \t]*inet \([0-9.]*\).*/\1/"`
IPADDR6=`/usr/sbin/ip -6 addr show dev eth0 | grep inet6 | sed "s/[ \t]*inet6 \([a-f0-9:]*\).*/\1/"`
export IPADDR4 IPADDR6

# set up resource limits for fluentd - from OpenShift/Origin logging-fluentd
BUFFER_SIZE_LIMIT=${BUFFER_SIZE_LIMIT:-1048576}
FLUENTD_CPU_LIMIT=${FLUENTD_CPU_LIMIT:-100m}
FLUENTD_MEMORY_LIMIT=${FLUENTD_MEMORY_LIMIT:-512Mi}

MEMORY_LIMIT=`echo $FLUENTD_MEMORY_LIMIT |  sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc`
BUFFER_SIZE_LIMIT=`echo $BUFFER_SIZE_LIMIT |  sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc`
if [ $BUFFER_SIZE_LIMIT -eq 0 ]; then
    BUFFER_SIZE_LIMIT=1048576
fi

BUFFER_QUEUE_LIMIT=`expr $MEMORY_LIMIT / $BUFFER_SIZE_LIMIT`
if [ $BUFFER_QUEUE_LIMIT -eq 0 ]; then
    BUFFER_QUEUE_LIMIT=1024
fi
export BUFFER_QUEUE_LIMIT BUFFER_SIZE_LIMIT

# launch fluentd - from OpenShift/Origin logging-fluentd
if [[ $DEBUG ]] ; then
    exec fluentd $fluentdargs > /var/log/fluentd.log 2>&1
else
    exec fluentd $fluentdargs
fi