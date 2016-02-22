#!/bin/bash

# Reference Tut: https://www.linode.com/docs/security/ssl/ssl-certificates-with-apache-2-on-ubuntu


apt-get update
apt-get install apache2
apt-get upgrade openssl

# Enable headers mod for hardening
a2enmod headers

# Edit the security file to reduce response Header information and add protections
nano /etc/apache2/conf-enabled/security.conf
# Change ServerTokens to "Minimal"

# Enforce a strong cipherlist, as copied from: https://cipherli.st/
file=/etc/apache2/conf-enabled/harden-ssl.conf
cat << EOF > ${file}
<IfModule mod_ssl.c>
	SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
	SSLProtocol All -SSLv2 -SSLv3
	SSLHonorCipherOrder On
	# SSLSessionTickets requires Apache >= 2.4.12
	#SSLSessionTickets Off
	Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains; preload"
	Header always set X-Frame-Options DENY
	Header always set X-Content-Type-Options nosniff
	# Requires Apache >= 2.4
	SSLCompression off 
	SSLUseStapling on 
	SSLStaplingCache "shmcb:logs/stapling-cache(150000)"
</IfModule>
EOF

# Enable SSL for Apache
a2enmod ssl

# Generate SSL certs
mkdir /etc/apache2/ssl/ && cd /etc/apache2/ssl/
openssl req -x509 -nodes -days 365 -newkey rsa:2048  -keyout apache.key -out apache.crt
# Protect the files
chmod 600 /etc/apache2/ssl/*

# enable SSL site
a2ensite default-ssl
# select "default-ssl" at interactive prompt

# Configure Apache to use SSL
nano /etc/apache2/sites-enabled/default-ssl.conf

# Look for the VirtualHost section for port 443, and modify it
# Below the line "ServerAdmin webmaster@localhost", add
ServerName 192.168.1.52:443
# Next, find the lines for the SSL Certificate configuration
SSLCertificateFile /etc/apache2/ssl/apache.crt
SSLCertificateKeyFile /etc/apache2/ssl/apache.key

# Finish
service apache2 restart
