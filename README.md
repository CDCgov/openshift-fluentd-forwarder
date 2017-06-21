# Fluentd Forwarder Container

## Table of Contents

* [Overview](#overview)
* [Bill of Materials](#bill-of-materials)
    * [Environment Specifications](#environment-specifications)
    * [Template Files](#template-files)
    * [Config Files](#config-files)
    * [External Source Code Repositories](#external-source-code-repositories)
* [Setup Instructions](#setup-instructions)
* [Presenter Notes](#presenter-notes)
    * [Environment Setup](#environment-setup)
    * [Produce Image](#produce-image)
    * [Create Fluentd Forwarder](#create-fluentd-forwarder)
    * [Configure Fluentd Loggers](#configure-fluentd-loggers)
    * [Additional Configuration](#additional-configuration)
    * [Validating the Application](#validating-the-application)
* [Resources](#resources)

## Overview

OpenShift can be configured to host an EFK stack that stores and indexes log data but at some sites a log aggregation system is already in place. A forwarding fluentd can be configured to forward log data to a remote collection point.

## Bill of Materials

### Environment Specifications

This quickstart should be run on an installation of OpenShift Enterprise V3 with an existing EFK deployment.

### Template Files

* [Application Template](./fluentd-forwarder-template.yaml)

### Config Files

None

### External Source Code Repositories

None

## Setup Instructions

Build the docker image in the [Dockerfile](./Dockerfile) and push to a repository that can be accessed by your OpenShift instance. Add the [template](./fluentd-forwarder-template.yaml) to the "logging" namespace.

## Presenter Notes

### Environment Setup

The EFK stack should already be configured in the "logging" namespace.

### Produce Image

To produce the image use the `docker build` command on the [Dockerfile](./Dockerfile) provided in this repository. Make the image available to the OpenShift instance and tagged with a version. (Usually the version is the version of fluentd in use.)

This project provides both a CentOS 7 and RHEL 7 image. The RHEL 7 is subject to the requirements of subscriptions for the RHEL 7 optional and software collection repositories.

### Create Fluentd Forwarder

Add the template to the logging namespace:
```bash
oc apply -n logging -f fluentd-forwarder-template.yaml
```

Create the new logging forwarder:
```bash
oc project logging
oc new-app fluentd-forwarder \
   -p "IMAGE_LOCATION=<registry cluster ip and namespace, ex: 172.30.12.40:5000/logging>" \
   -p "IMAGE_VERSION=<version pushed, ex: 0.12.32>" \
   -p "TARGET_TYPE=remote_syslog" \
   -p "TARGET_HOST=rsyslog.internal.company.com" \
   -p "TARGET_PORT=514" \
   -p "SHARED_KEY=changeme"
```

A full list of parameters can be found in the [template](./fluentd-forwarder-template.yaml). Additional non-parameterized parameters and environment variables can be found in the [Dockerfile](./Dockerfile).

### Configure Fluentd Loggers

The "logging-fluentd" configmap's "data.secure-forward.conf" key needs to be edited as well.
```bash
oc edit configmap -n logging logging-fluentd
```

Edit the following YAML:

```yaml
data:
  secure-forward.conf: |
    @type secure_forward
 
    self_hostname ${HOSTNAME}
    shared_key newsharedkey
 
    secure yes
    enable_strict_verification yes
 
    ca_cert_path /var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt
 
    <server>
       host fluentd-forwarder.logging.svc.cluster.local
       port 24284
    </server>
```

This will cause each individual fluentd logger to begin forwarding to the service address `fluentd-forwarder.logging.svc.cluster.local` which was created with the new-app command. That service has it's own cluster-generated certificates and the "ca_cert_path" value here is used to trust the cluster's service signer CA.

After saving the above changes the logging-fluentd pods need to be restarted. Delete them and they will be recreated.
```bash
oc delete pod -l component=fluentd
```

### Additional Configuration
After creating the application you can edit the configuration for the logging forwarder in a more direct manner by manipulating the configuration map.
```bash
oc edit configmap -n logging fluentd-forwarder
```

This will allow you to edit a copy of the configuration template and override the one provided in the Docker container without performing a rebuild.

Any environment variables (like `SHARED_KEY` or `TARGET_TYPE`) will be substituted during the Pod startup just as with the built-in template using the `envsubst` command. Additional parameters can be added to the deployment config or directly edited here.

```yaml
data:
  fluentd.conf: |
    <source>
      @type secure_forward
      self_hostname "#{ENV['HOSTNAME']}"
      bind 0.0.0.0
      port 24284

      shared_key ${SHARED_KEY}

      secure           ${IS_SECURE}
      enable_strict_verification ${STRICT_VERIFICATION}

      ca_cert_path     ${CA_PATH}
      cert_path        ${CERT_PATH}
      private_key_path ${KEY_PATH}

      private_key_passphrase ${KEY_PASSPHRASE}
    </source>

    <filter **>
      @type record_transformer
      <record>
        forwarded_by "#{ENV['HOSTNAME']}"
        source_component "OCP"
      </record>
    </filter>

    <match **>
      type ${TARGET_TYPE}
      host ${TARGET_HOST}
      port ${TARGET_PORT}
      output_format json
    </match>
```

If you save changes to this configuration map you will need to delete the pods for the deployment so they can be recreated.

```bash
oc delete pods -l name=fluentd-forwarder
```

### Validating the Application
The best verification is that logs are showing up in the remote location. The application sets two tags "forwarded_by" which is set to the pod's hostname and "source_component" which is always set to "OCP". You can use those tags to search the logging collection facility for the logs being produced.

If VERBOSE is set as an environment variable in the deployment config (`oc edit dc fluentd-forwarder`) then you can tail the logs of the fluentd-forwarder container and you should see a lot of information about reads. This is not the most reliable test but it will at least point in the right direction.
 
```bash
oc logs fluentd-forwarder-1-a3zdf
2017-06-19 21:05:20 +0000 [debug]: plugin/input_session.rb:122:on_read: on_read
2017-06-19 21:05:23 +0000 [debug]: plugin/input_session.rb:122:on_read: on_read
2017-06-19 21:05:24 +0000 [debug]: plugin/input_session.rb:122:on_read: on_read
2017-06-19 21:05:25 +0000 [debug]: plugin/input_session.rb:122:on_read: on_read
2017-06-19 21:05:25 +0000 [debug]: plugin/input_session.rb:122:on_read: on_read
2017-06-19 21:05:25 +0000 [debug]: plugin/input_session.rb:122:on_read: on_read
2017-06-19 21:05:25 +0000 [debug]: plugin/input_session.rb:122:on_read: on_read
2017-06-19 21:05:26 +0000 [debug]: plugin/input_session.rb:122:on_read: on_read
2017-06-19 21:05:26 +0000 [debug]: plugin/input_session.rb:122:on_read: on_read
```

## Resources
* [Secure Forwarding with Splunk](https://playbooks-rhtconsulting.rhcloud.com/playbooks/operationalizing/secure-forward-splunk.html)