





# =============================[   APT   ]================================ #
# https://wiki.debian.org/SourcesList
echo -e "\n${GREEN}[*]${RESET} Setting sources.list to standard entries"
if [[ $SUDO ]]; then
  echo "# Debian Jessie" | $SUDO tee /etc/apt/sources.list
  echo "deb http://httpredir.debian.org/debian jessie main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  echo "deb-src http://httpredir.debian.org/debian jessie main contrib non-free" | $SUDO tee -a /etc/apt/sources.list

  echo "deb http://httpredir.debian.org/debian jessie-updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  echo "deb-src http://httpredir.debian.org/debian jessie-updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list

  echo "deb http://security.debian.org/ jessie/updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  echo "deb-src http://security.debian.org/ jessie/updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
  
  # Testing and Unstable repo's
  # WARNING: Only add these if you also setup apt-pinning rules before running any apt-get commands
  # or your entire distro will be updated to 'unstable' which is not wise.
	echo "" | $SUDO tee -a /etc/apt/sources.list
	echo "# Testing" | $SUDO tee -a /etc/apt/sources.list
	echo "deb http://httpredir.debian.org/debian testing main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
	echo "deb-src http://httpredir.debian.org/debian testing main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
	echo "" | $SUDO tee -a /etc/apt/sources.list
	echo "deb http://security.debian.org/ testing/updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
	echo "deb-src http://security.debian.org/ testing/updates main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
	echo "" | $SUDO tee -a /etc/apt/sources.list
	echo "# Unstable" | $SUDO tee -a /etc/apt/sources.list
	echo "deb http://httpredir.debian.org/debian unstable main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
	echo "deb-src http://httpredir.debian.org/debian unstable main contrib non-free" | $SUDO tee -a /etc/apt/sources.list
else
  echo "# Debian Jessie" > /etc/apt/sources.list
  echo "deb http://httpredir.debian.org/debian jessie main contrib non-free" >> /etc/apt/sources.list
  echo "deb-src http://httpredir.debian.org/debian jessie main contrib non-free" >> /etc/apt/sources.list

  echo "deb http://httpredir.debian.org/debian jessie-updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb-src http://httpredir.debian.org/debian jessie-updates main contrib non-free" >> /etc/apt/sources.list

  echo "deb http://security.debian.org/ jessie/updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb-src http://security.debian.org/ jessie/updates main contrib non-free" >> /etc/apt/sources.list
  # Testing and Unstable repo's
  # WARNING: Only add these if you also setup apt-pinning rules before running any apt-get commands
  # or your entire distro will be updated to 'unstable' which is not wise.
	echo "# Testing" >> /etc/apt/sources.list
	echo "deb http://httpredir.debian.org/debian testing main contrib non-free" >> /etc/apt/sources.list
	echo "deb-src http://httpredir.debian.org/debian testing main contrib non-free" >> /etc/apt/sources.list
	echo "" >> /etc/apt/sources.list
	echo "deb http://security.debian.org/ testing/updates main contrib non-free" >> /etc/apt/sources.list
	echo "deb-src http://security.debian.org/ testing/updates main contrib non-free" >> /etc/apt/sources.list
	echo "" >> /etc/apt/sources.list
	echo "# Unstable" >> /etc/apt/sources.list
	echo "deb http://httpredir.debian.org/debian unstable main contrib non-free" >> /etc/apt/sources.list
	echo "deb-src http://httpredir.debian.org/debian unstable main contrib non-free" >> /etc/apt/sources.list
fi


# =======[ Configure Apt-pinning rules ]==============
file=/etc/apt/preferences.d/my_preferences

echo -e "Adding apt-pinning rules so that regular updates remain on the stable track"
#$SUDO nano "${file}"

# TODO: Add the rules here and cat it to the "${file}" using chmod perms statements
cat <<EOF > /tmp/my_preferences
Package: *
Pin: release a=stable
Pin-Priority: 700

Package: *
Pin: release a=testing
Pin-Priority: 650

Package: *
Pin: release a=unstable
Pin-Priority: 600
EOF
$SUDO mv /tmp/my_preferences "${file}"
$SUDO chmod -f 0644 "${file}"

# Confirm the pinning configuration is correct
# The output of this should indicate exactly which sources line the package will come from
# As of right now, apache version is 2.4.10 on 'stable', but 2.4.24-3 on 'testing'

#apt-cache policy apache2
#apt-cache policy conky
#pause


# Testing/unstable packages can now be installed via:
	# Method 1: This installs pkg from testing, but install dependencies from stable
#		apt-get install apache2/testing
	# Method 2 (BETTER CHOICE): This installs pkg from testing, and dependencies also from testing
#	apt-get -t testing install apache2


# =============[ CONKY ]===============
echo -e "${GREEN}[*]${RESET} Installing Conky pkg..."
$SUDO apt-get -y -t testing install conky
