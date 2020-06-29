#!/bin/bash
mkdir -p ${HOME} && \

# install gems for target version of fluentd, eventually
# update to fluentd version that matches version deployed
# into openshift
gem install -N --conservative --minimal-deps --no-document \
  'tzinfo:<1.0.0' \
  'fluentd:1.5.2' \
  'activesupport:<5' \
  'public_suffix:<3.0.0' \
  'fluent-plugin-record-modifier:<1.0.0' \
  'fluent-plugin-rewrite-tag-filter:<2.0.0' \
  'fluent-plugin-kubernetes_metadata_filter:2.2.0' \
  'fluent-plugin-rewrite-tag-filter:2.2.0' \
  'fluent-plugin-secure-forward:0.4.2' \
  'fluent-plugin-remote_syslog:<1.0.0' \
  'fluent-plugin-splunk-hec:1.1.2'

# set up directores so that group 0 can have access like specified in
# https://docs.openshift.com/container-platform/3.7/creating_images/guidelines.html
# https://docs.openshift.com/container-platform/3.7/creating_images/guidelines.html#openshift-specific-guidelines
mkdir -p /etc/fluent
chgrp -R 0 /etc/fluent
chmod -R  a+rwx,u-x,g-w,o-w /etc/fluent
chgrp -R 0 ${HOME}
chmod -R a+rwx,u-x,g-w,o-w ${HOME}
chgrp -R 0 /etc/pki
chmod -R  a+rwx,u-x,g-w,o-w /etc/pki
mkdir /secrets
chgrp -R 0 /secrets
chmod -R  a+rwx,u-x,g-w,o-w /secrets
chgrp -R 0 /var/log
chmod -R  a+rwx,u-x,g-w,o-w /var/log
