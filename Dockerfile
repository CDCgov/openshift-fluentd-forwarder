# start based on a centos image
FROM ubi8

#ENV HOME=/opt/app-root/src \
#  PATH=/opt/app-root/src/bin:/opt/app-root/bin${PATH:+:${PATH}} \
#  LD_LIBRARY_PATH=/opt/rh/rh-ruby23/root/usr/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} \
#  MANPATH=/opt/rh/rh-ruby23/root/usr/share/man:$MANPATH \
#  PKG_CONFIG_PATH=/opt/rh/rh-ruby23/root/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}} \
#  XDG_DATA_DIRS=/opt/rh/rh-ruby23/root/usr/share${XDG_DATA_DIRS:+:${XDG_DATA_DIRS}} \
#  RUBY_VERSION=2.5 \
#  FLUENTD_VERSION=1.5.2 \
#  DATA_VERSION=1.6.0 \
##  TARGET_TYPE=remote_syslog \
#  TARGET_HOST=localhost \
#  TARGET_PORT=24284 \
#  IS_SECURE=yes \
#  STRICT_VERIFICATION=yes \
#  KEY_PASSPHRASE= \
#  SHARED_KEY=ocpaggregatedloggingsharedkey

LABEL io.k8s.description="Fluentd container for collecting logs from other fluentd instances" \
  io.k8s.display-name="Fluentd Forwarder (${FLUENTD_VERSION})" \
  io.openshift.expose-services="24284:tcp" \
  io.openshift.tags="logging,fluentd,forwarder" \
  name="fluentd-forwarder" \
  architecture=x86_64
USER 0
# add files
#ADD run.sh fluentd.conf.template passwd.template fluentd-check.sh ${HOME}/
#ADD common-*.sh /tmp/

# set permissions on files
#RUN chmod g+rx ${HOME}/fluentd-check.sh && \
#    chmod +x /tmp/common-*.sh

COPY ./etc-pki-entitlement /etc/pki/entitlement
ADD ubi.repo /etc/yum.repos.d/ubi.repo


RUN INSTALL_PKGS="gcc-c++ libcurl-devel procps make bc gettext nss_wrapper hostname rh-ruby26 rh-ruby26-ruby-devel rh-ruby26-rubygem-rake rh-ruby26-rubygem-bundler autoconf automake" && \
    DISABLE_REPOS="--disablerepo='rhel-*'" && \
    ls /etc/pki/entitlement && \
    rm /etc/rhsm-host && \
    yum repolist > /dev/null && \
    yum clean all && yum upgrade -y && yum update -y --skip-broken && \
    subscription-manager remove --all && \
    subscription-manager unregister && \
    subscription-manager clean && \
    subscription-manager register && \
    subscription-manager refresh && \
    subscription-manager attach --auto && \
    yum $DISABLE_REPOS install -y --setopt=tsflags=nodocs $INSTALL_PKGS && rpm -V $INSTALL_PKGS && \
    yum $DISABLE_REPOS clean all -y && \
    rm -rf /var/cache/yum


# execute files and remove when done
RUN /tmp/common-install.sh && \
    rm -f /tmp/common-*.sh

# set working dir

# external port
EXPOSE 24284

USER 1001
WORKDIR ${HOME}
CMD ["sh", "run.sh"]
