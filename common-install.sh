#!/bin/bash

# get release version
RELEASE=$(cat /etc/redhat-release)
YUM_ARGS="--setopt=tsflags=nodocs"

# ensure latest versions
yum update $YUM_ARGS -y

# shared packages
PACKAGES="gcc-c++ libcurl-devel make bc gettext nss_wrapper hostname iproute"

# ruby packages
PACKAGES="${PACKAGES} rh-ruby22 rh-ruby22-rubygems rh-ruby22-ruby-devel"

# if the release is a red hat version then we need to set additional arguments for yum repositories
RED_HAT_MATCH='^Red Hat.*$'
if [[ $RELEASE =~ $RED_HAT_MATCH ]]; then
  YUM_ARGS="${YUM_ARGS} --disablerepo=\* --enablerepo=rhel-7-server-rpms --enablerepo=rhel-server-rhscl-7-rpms --enablerepo=rhel-7-server-optional-rpms"
fi

# enable epel when on CentOS
CENTOS_MATCH='^CentOS.*'
if [[ $RELEASE =~ $CENTOS_MATCH ]]; then
  rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
  yum install -y epel-release centos-release-scl-rh
fi

# install all required packages
yum install -y $YUM_ARGS $PACKAGES

# clean up yum to make sure image isn't larger because of installations/updates
yum clean all
rm -rf /var/cache/yum/*
rm -rf /var/lib/yum/*

# set home directory
mkdir -p ${HOME} && \

# install gems for target version of fluentd, eventually
# update to fluentd version that matches version deployed
# into openshift
gem install -N --conservative --minimal-deps --no-document \
  fluentd:${FLUENTD_VERSION} \
  'activesupport:<5' \
  'public_suffix:<3.0.0' \
  'fluent-plugin-record-modifier:<1.0.0' \
  'fluent-plugin-rewrite-tag-filter:<2.0.0' \
  fluent-plugin-kubernetes_metadata_filter \
  fluent-plugin-rewrite-tag-filter \
  fluent-plugin-secure-forward \
  'fluent-plugin-remote_syslog:<1.0.0' \
  fluent-plugin-splunk-ex

# set up directores
mkdir -p /etc/fluent
chgrp -R 0 /etc/fluent
chmod -R g+rwX /etc/fluent
chgrp -R 0 ${HOME}
chmod -R g+rwX ${HOME}
chgrp -R 0 /etc/pki
chmod -R g+rwX /etc/pki
mkdir /secrets
chgrp -R 0 /secrets
chmod -R g+rwX /secrets
chgrp -R 0 /var/log
chmod -R g+rwX /var/log
