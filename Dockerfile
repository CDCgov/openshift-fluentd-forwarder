# start based on a centos image
FROM rhel7

ENV HOME=/opt/app-root/src \
  PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH \
  RUBY_VERSION=2.0 \
  FLUENTD_VERSION=0.12.32 \
  GEM_HOME=/opt/app-root/src \
  DATA_VERSION=1.6.0 \
  TARGET_TYPE=remote_syslog \
  TARGET_HOST=localhost \
  TARGET_PORT=24284 \
  IS_SECURE=yes \
  STRICT_VERIFICATION=yes \
  CA_PATH=/etc/pki/CA/certs/ca.crt \
  CERT_PATH=/etc/pki/tls/certs/local.crt \
  KEY_PATH=/etc/pki/tls/private/local.key \
  KEY_PASSPHRASE= \
  SHARED_KEY=ocpaggregatedloggingsharedkey

LABEL io.k8s.description="Fluentd container for collecting logs from other fluentd instances" \
  io.k8s.display-name="Fluentd Forwarder (${FLUENTD_VERSION})" \
  io.openshift.expose-services="24284:tcp \
  io.openshift.tags="logging,fluentd,forwarder" \
  name="fluentd-forwarder" \
  architecture=x86_64

# build tools for building gems
# iproute needed for ip command to get ip addresses
# nss_wrapper used to support username identity
# bc for calculations in run.conf
RUN yum install -y --disablerepo=\* --enablerepo=rhel-7-server-rpms --enablerepo=rhel-server-rhscl-7-rpms --enablerepo=rhel-7-server-optional-rpms --setopt=tsflags=nodocs \
      gcc-c++ \
      ruby \
      ruby-devel \
      libcurl-devel \
      make \
      bc \
      gettext \
      nss_wrapper \
      hostname \
      iproute && \
    yum clean all

# activesupport version 5.x requires ruby 2.2
RUN mkdir -p ${HOME} && \
    gem install -N --conservative --minimal-deps --no-document \
      fluentd:${FLUENTD_VERSION} \
      'activesupport:<5' \
      fluent-plugin-kubernetes_metadata_filter \
      fluent-plugin-rewrite-tag-filter \
      fluent-plugin-secure-forward \
      fluent-plugin-remote_syslog \
      fluent-plugin-splunk-ex

RUN mkdir -p /etc/fluent && \
    chgrp -R 0 /etc/fluent && \
    chmod -R g+rwX /etc/fluent && \
    chgrp -R 0 ${HOME} && \
    chmod -R g+rwX ${HOME} && \
    chgrp -R 0 /etc/pki && \
    chmod -R g+rwX /etc/pki && \
    mkdir /secrets && \
    chgrp -R 0 /secrets && \
    chmod -R g+rwX /secrets  && \
    chgrp -R 0 /var/log && \
    chmod -R g+rwX /var/log     

# copy configuration files
ADD run.sh fluentd.conf.template passwd.template fluentd-check.sh ${HOME}/
RUN chmod g+rx ${HOME}/fluentd-check.sh

# set working dir
WORKDIR ${HOME}

# external port
EXPOSE 24284

CMD ["sh", "run.sh"]