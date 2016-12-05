#!/bin/sh
set -ex

chown -R prosody:prosody /var/lib/prosody
chmod -R ug+rwX /var/lib/prosody

saslauthd -a ldap

/ldap2prosody.lua
/removeusers.lua

cp -Rf /srv/prosody/certs/* /etc/prosody/certs/
chown -R root:prosody /etc/prosody/certs/
chmod 0640 /etc/prosody/certs/*

prosodyctl start
