#!/bin/bash

# Setup hostname
sed -i "s/debian/$(hostname)/g" /etc/hosts

# Customize bashrc
echo "export PS1='\[\033[36m\]\h \[\033[1;32m\][ \w ]▶ \[\033[00m\]'"  >> ~/.bashrc
echo "bind '"\\e[A": history-search-backward'" >> ~/.bashrc
echo "bind '"\\e[B": history-search-forward'" >> ~/.bashrc

# Add aliases and functions
tee -a ~/.bashrc <<EOF
alias l="ls -al"
alias gt="gotop -c monokai"
alias ct="systemd-cgtop -m"
function de() {
	docker exec -it $1 /bin/bash
}
function dh() {
	if [ -z "\$1" ]; then
		export DOCKER_HOST=unix:///var/run/docker.sock
		return
	fi

	if [ ! -S "/var/sec/engine.\$1.sock" ]; then
		echo "Socket /var/sec/engine.\$1.sock does not exist"
		return
	fi

	export DOCKER_HOST=unix:///var/sec/engine.\$1.sock
}
function cdh() {
	if [ -z "\$DOCKER_HOST" ]; then
		echo "unix:///var/run/docker.sock"
		return
	fi

	echo "\$DOCKER_HOST"
}
EOF

# Install essential packages
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
sudo apt-get update
sudo apt-get install -y htop nload iotop curl wget iptables-persistent ca-certificates gnupg lsb-release apt-transport-https

# Install Docker
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Gotop
wget -O /tmp/gotop.deb https://github.com/cjbassi/gotop/releases/download/3.0.0/gotop_3.0.0_linux_amd64.deb
sudo dpkg -i /tmp/gotop.deb

# Enable IPv4 forwarding
sysctl -w net.ipv4.ip_forward=1
sysctp -p

# Cleanup
sudo rm -r /tmp/*

# Source bashrc
source ~/.bashrc
