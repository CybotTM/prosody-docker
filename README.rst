Netresearch Prosody docker image
================================

Prosody jabber/XMPP server.

- LDAP/AD auth with cyrus SASL
- shared rooster with users from LDAP/AD
- shared chat rooms
- MUC logging

Install
-------

::

    docker run --rm -ti \
        -v /path/to/certs/company.crt:/srv/prosody/certs/default.crt \
        -v /path/to/certs/company.key:/srv/prosody/certs/default.key \
        -v /path/to/saslauthd.conf:/etc/saslauthd.conf \
        -v /path/to/example.org.virtualhost.lua:/etc/prosody/conf.d/ \
        -v /path/to/proxy.component.lua:/etc/prosody/conf.d/ \
        -v /path/to/muc.component.lua:/etc/prosody/conf.d/ \
        -p 5222:5222 -p 5269:5269 -p 5347:5347 -p 5280:5280 -p 5281:5281 \
        netresearch/prosody


scheduler
.........

crontab::

    # update jabber (xmpp, prosody) user list
    5 0 * * * cd /etc/docker-compose/xmpp.nr && /usr/local/bin/docker-compose exec -T prosody ./removeusers.lua
    6 0 * * * cd /etc/docker-compose/xmpp.nr && /usr/local/bin/docker-compose exec -T prosody ./ldap2prosody.lua
    10 0 * * * cd /etc/docker-compose/xmpp.nr && /usr/local/bin/docker-compose exec -T prosody prosodyctl reload > /dev/null


TODO
----

- get mod_ldap working to get rid of saslauth daemon
- figure out which additional ports need to be made public
- use libevent: https://prosody.im/doc/libevent
- test if groups/users get updated after ldap2prosody is run - if not: https://modules.prosody.im/mod_reload_modules.html
