################################################################################
# Build a dockerfile for Prosody XMPP server
# https://github.com/prosody/prosody-docker/tree/alpine
################################################################################

FROM debian:jessie-slim

RUN set -ex \
 && apt-get update \
 && apt-get upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends \
 && apt-get install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends \
    # packages required to install system
    curl ca-certificates \
    # packages required for prosody and modules
    sasl2-bin lua-cyrussasl libsasl2-modules-ldap lua-sec \
    # packages required for lua maintenance scripts
    lua-ldap ldap-utils \
 # install prosody
 && echo deb http://packages.prosody.im/debian jessie main | tee -a /etc/apt/sources.list \
 && curl https://prosody.im/files/prosody-debian-packages.key | apt-key add - \
 && apt-get update \
 && apt-get install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends \
    prosody

# allow prosody accessing sasl socket for LDAP authentication
RUN usermod -a -G sasl prosody

# add prosody modules
ADD https://hg.prosody.im/prosody-modules/raw-file/tip/mod_post_msg/mod_post_msg.lua /usr/lib/prosody/modules/
ADD https://hg.prosody.im/prosody-modules/raw-file/tip/mod_webpresence/mod_webpresence.lua /usr/lib/prosody/modules/
ADD https://hg.prosody.im/prosody-modules/raw-file/tip/mod_group_bookmarks/mod_group_bookmarks.lua /usr/lib/prosody/modules/
ADD https://hg.prosody.im/prosody-modules/raw-file/tip/mod_muc_log/mod_muc_log.lua /usr/lib/prosody/modules/
#ADD https://hg.prosody.im/prosody-modules/raw-file/tip/mod_auth_ldap/mod_auth_ldap.lua /usr/lib/prosody/modules/
ADD https://hg.prosody.im/prosody-modules/archive/tip.tar.gz/mod_muc_log_http/ /usr/lib/prosody/modules/mod_muc_log_http.tar.gz
RUN tar -xzf /usr/lib/prosody/modules/mod_muc_log_http.tar.gz -C /usr/lib/prosody/modules/
RUN mv /usr/lib/prosody/modules/prosody-modules-*/mod_muc_log_http/muc_log_http/* /usr/lib/prosody/modules/
RUN rm -rf /usr/lib/prosody/modules/prosody-modules-*

RUN chmod -R ugo+r /usr/lib/prosody/modules/

ADD setup/ /

VOLUME ["/var/log", "/var/lib/prosody", "/run/saslauthd"]

EXPOSE 80 443 5222 5269 5347 5280 5281
ENV __FLUSH_LOG yes
CMD ["/run.sh"]
