#!/bin/bash

#judgement
if [[ -a /etc/supervisor/conf.d/supervisord.conf ]]; then
  exit 0
fi

#supervisor
cat > /etc/supervisor/conf.d/supervisord.conf <<EOF
[supervisord]
nodaemon=true

[program:postfix]
command=/opt/postfix.sh

[program:rsyslog]
command=/usr/sbin/rsyslogd -n -c3
EOF

############
#  postfix
############
cat >> /opt/postfix.sh <<EOF
#!/bin/bash
service postfix start
tail -f /var/log/mail.log
EOF
chmod +x /opt/postfix.sh
postconf -e append_dot_mydomain=no
postconf -e biff=no
postconf -e inet_interfaces=all 
postconf -F '*/*/chroot = n'

############
# SASL SUPPORT FOR RELAY 
# Cyrus-SASL support for authentication to a relay host.
############
# /etc/postfix/main.cf
postconf -e relayhost=$relayhost
postconf -e smtp_sasl_auth_enable=yes
postconf -e smtp_sasl_password_maps=hash:/etc/sasl_passwd
postconf -e smtp_sasl_security_options=noanonymous 
postconf -e smtp_tls_CAfile=/etc/postfix/cacert.pem
postconf -e smtp_tls_session_cache_database=btree:${data_directory}/smtp_scache
postconf -e smtp_use_tls=yes
postconf -e smtpd_tls_CAfile=/etc/postfix/cacert.pem
postconf -e smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
postconf -e smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
postconf -e smtpd_tls_session_cache_database=btree:${data_directory}/smtpd_scache
postconf -e smtpd_use_tls=yes
postconf -e mynetworks=172.17.0.0/16

# sasl_passwd file setup
echo $smtp_user > /etc/sasl_passwd
postmap /etc/sasl_passwd
chown postfix.sasl /etc/sasl_passwd*
