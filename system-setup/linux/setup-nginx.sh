#!/bin/bash




# Ref: https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-on-debian-8


# Nginx on Debian 8
# ===================

# Install nginx
sudo apt-get update
sudo apt-get install nginx

# On Debian 8, Nginx is configured to start running upon installation.

# If you have the ufw firewall running, you will need to allow connections to Nginx. You should enable the most restrictive profile that will still allow the traffic you want. Since we haven't configured SSL for our server yet, in this guide, we will only need to allow traffic on port 80.

# You can enable this by typing:
sudo ufw allow 'Nginx HTTP'

# You can verify the change by typing:
sudo ufw status
# You should see HTTP traffic allowed in the displayed output:

Output
Status: active

# To                         Action      From
# --                         ------      ----
# OpenSSH                    ALLOW       Anywhere                  
# Nginx HTTP                 ALLOW       Anywhere                  
# OpenSSH (v6)               ALLOW       Anywhere (v6)             
# Nginx HTTP (v6)            ALLOW       Anywhere (v6)
# Now, test if the server is up and running by accessing your server's domain name or public IP address in your web browser. If you do not have a domain name pointed at your server and you do not know your server's public IP address, you can find it by typing one of the following into your terminal:

ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

# This will print out a few IP addresses. You can try each of them in turn in your web browser.

# As an alternative, you can check which IP address is accessible as viewed from other locations on the internet:

curl -4 icanhazip.com

# Type one of the addresses that you receive in your web browser. It should take you to Nginx's default landing page:

# http://server_domain_or_IP
firefox http://localhost &




# =====================[ Setting up for use with PHP ]=====================

# Since Nginx does not contain native PHP processing like some other web servers, we will need to install fpm, which stands for "fastCGI process manager". We will tell Nginx to pass PHP requests to this software for processing. We'll also install an additional helper package that will allow PHP to communicate with our MySQL database backend. The installation will pull in the necessary PHP core files to make that work.

# These packages aren't available in the default repositories due to licensing issues, so we'll have to modify the repository sources to pull them in.

# Open /etc/apt/sources.list in your text editor:
sudo nano /etc/apt/sources.list

# Then, for each source, append the contrib and non-free repositories to each source. Your file should look like the following after you've made those changes:
/etc/apt/sources.list

# ...
# deb http://mirrors.digitalocean.com/debian jessie main contrib non-free
# deb-src http://mirrors.digitalocean.com/debian jessie main contrib non-free
#
# deb http://security.debian.org/ jessie/updates main contrib non-free
# deb-src http://security.debian.org/ jessie/updates main contrib non-free
#
## jessie-updates, previously known as 'volatile'
# deb http://mirrors.digitalocean.com/debian jessie-updates main contrib non-free
# deb-src http://mirrors.digitalocean.com/debian jessie-updates main contrib non-free

# Save and exit the file. Then update your sources:
sudo apt-get -qq update

# Then install the php5-fpm and php5-mysql modules:
sudo apt-get install php5-fpm php5-mysql

# We now have our PHP components installed, but we need to make a slight configuration change to make our setup more secure.

# Open the main php-fpm configuration file with root privileges:
sudo nano /etc/php5/fpm/php.ini

# Look in the file for the parameter that sets cgi.fix_pathinfo. This will be commented out with a semi-colon (;) and set to "1" by default.

# This is an extremely insecure setting because it tells PHP to attempt to execute the closest file it can find if the requested PHP file cannot be found. This basically would allow users to craft PHP requests in a way that would allow them to execute scripts that they shouldn't be allowed to execute.

# We will change both of these conditions by uncommenting the line and setting it to "0"

#   cgi.fix_pathinfo=0

# Save and close the file when you are finished.

# Now, we just need to restart our PHP processor by typing:
sudo systemctl restart php5-fpm


# ================[ Step 4 — Configure Nginx to Use the PHP Processor ]=================

# Now, we have all of the required components installed. The only configuration change we still need is to tell Nginx to use our PHP processor for dynamic content.

# We do this on the server block level (server blocks are similar to Apache's virtual hosts). Open the default Nginx server block configuration file by typing:
sudo nano /etc/nginx/sites-available/default

# Currently, with the comments removed, the Nginx default server block file looks like this:







# We need to make some changes to this file for our site.

# First, we need to add index.php as the first value of our index directive so that files named index.php are served, if available, when a directory is requested.

# We can modify the server_name directive to point to our server's domain name or public IP address.
# For the actual PHP processing, we just need to uncomment a segment of the file that handles PHP requests. This will be the location ~\.php$ location block, the included fastcgi-php.conf snippet, and the socket associated with php-fpm.

# We will also uncomment the location block dealing with .htaccess files. Nginx doesn't process these files. If any of these files happen to find their way into the document root, they should not be served to visitors.

# Edit the file -NOTE: This is only if you are using PHP and homepage is "index.php"
file=/etc/nginx/sites-available/default
SERVER_NAME='localhost'
SERVER_IP=0.0.0.0
cat <<EOF > "${file}
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm index.nginx-debian.html;

    ${SERVER_NAME} ${SERVER_IP};

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF


# When you've made the above changes, you can save and close the file.

# Test your configuration file for syntax errors by typing:
sudo nginx -t
# If any errors are reported, go back and recheck your file before continuing.

# When you are ready, reload Nginx to make the necessary changes:
sudo systemctl reload nginx





