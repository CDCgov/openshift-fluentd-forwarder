# start based on a centos image
FROM rhel7

ENV HOME=/opt/app-root/src \
  PATH=/opt/rh/rh-ruby22/root/usr/bin:/opt/app-root/src/bin:/opt/app-root/bin${PATH:+:${PATH}} \
  LD_LIBRARY_PATH=/opt/rh/rh-ruby22/root/usr/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} \
  MANPATH=/opt/rh/rh-ruby22/root/usr/share/man:$MANPATH \
  PKG_CONFIG_PATH=/opt/rh/rh-ruby22/root/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}} \
  XDG_DATA_DIRS=/opt/rh/rh-ruby22/root/usr/share${XDG_DATA_DIRS:+:${XDG_DATA_DIRS}} \
  RUBY_VERSION=2.2 \
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
  io.openshift.expose-services="24284:tcp" \
  io.openshift.tags="logging,fluentd,forwarder" \
  name="fluentd-forwarder" \
  architecture=x86_64

# add files
ADD run.sh fluentd.conf.template passwd.template fluentd-check.sh ${HOME}/
ADD common-*.sh /tmp/

# set permissions on files
RUN chmod g+rx ${HOME}/fluentd-check.sh && \
    chmod +x /tmp/common-*.sh

# execute files and remove when done
RUN /tmp/common-install.sh && \
    rm -f /tmp/common-*.sh

# set working dir
WORKDIR ${HOME}

# external port
EXPOSE 24284

CMD ["sh", "run.sh"]
