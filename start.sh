#!/bin/bash

if [[ ! -f /var/run/.stamp_installed ]]; then
  if [[ -z "${BIND9_ROOTDOMAIN}" ]];then
    echo "The variable BIND9_ROOTDOMAIN must be set"
    exit 1
  fi
  if [[ -z "${BIND9_KEYNAME}" ]];then
    echo "The variable BIND9_KEYNAME must be set"
    exit 1
  fi
  if [[ -z "${BIND9_KEY}" ]];then
    echo "The variable BIND9_KEY must be set"
    exit 1
  fi
  echo "Creating key configuration"
  cat <<EOF > /etc/bind/tsig.key
key "${BIND9_KEYNAME}" {
  algorithm hmac-md5;
  secret "${BIND9_KEY}";
};
EOF
  echo "Creating named configuration"
  cat <<EOF > /etc/bind/named.conf.local
include "/etc/bind/tsig.key";
zone "${BIND9_ROOTDOMAIN}" {
       type master;
       file "/etc/bind/zones/db.${BIND9_ROOTDOMAIN}";
       allow-update { key "${BIND9_KEYNAME}"; } ;
};
EOF
  echo "Creating ${BIND9_ROOTDOMAIN} configuration"
  cat <<EOF >> "/etc/bind/zones/db.${BIND9_ROOTDOMAIN}" 
@		IN SOA	ns.${BIND9_ROOTDOMAIN}. root.${BIND9_ROOTDOMAIN}. (
				20041125   ; serial
				604800     ; refresh (1 week)
				86400      ; retry (1 day)
				2419200    ; expire (4 weeks)
				604800     ; minimum (1 week)
				)
			NS	ns.${BIND9_ROOTDOMAIN}.
ns			A	127.0.0.1
EOF
  chown -R bind:bind /etc/bind/zones/
  touch /var/run/.stamp_installed
fi

named -g -c /etc/bind/named.conf -u bind
