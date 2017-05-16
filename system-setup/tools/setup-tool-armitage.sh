








# 1: Install armitage
# 2: Ensure postgresql is running - systemctl start postgresql
# 3: Ensure msfconsole is operational - msfconsole
# 4: Start armitage - armitage



# Install Armitage from source
curl -# -o /tmp/armitage.tgz http://www.fastandeasyhacking.com/download/armitage-latest.tgz
$SUDO tar -xvzf /tmp/armitage.tgz -C /opt
$SUDO ln -s /opt/armitage/armitage /usr/local/bin/armitage
$SUDO ln -s /opt/armitage/teamserver /usr/local/bin/teamserver
$SUDO sh -c "echo java -jar /opt/armitage/armitage.jar \$\* > /opt/armitage/armitage"
$SUDO perl -pi -e 's/armitage.jar/\/opt\/armitage\/armitage.jar/g' /opt/armitage/teamserver





# Armitage
#       Default install is via: apt-get install armitage
#
# Defaults:
#       Host: 127.0.0.1
#       Login: msf:test
#       Port: 55553



# Configure Postgresql (if you need to)
#sudo -s
#su postgres
#createuser msf -P -S -R -D
#createdb -O msf msf
#exit
#exit

