#!/usr/bin/env bash
set -euo pipefail

# System Configuration for automated installation
export DEBIAN_FRONTEND=noninteractive
needrestart_conf_dir="/etc/needrestart/conf.d" 
needrestart_conf_file="${needrestart_conf_dir}/temp-disable-for-edgebox-install.conf"
sudo mkdir -p "${needrestart_conf_dir}"
echo "# Restart services (l)ist only, (i)nteractive or (a)utomatically.
\$nrconf{restart} = 'l';
# Disable hints on pending kernel upgrades.
\$nrconf{kernelhints} = 0; " | sudo tee "${needrestart_conf_file}" > /dev/null
trap "sudo rm -f ${needrestart_conf_file}" EXIT

# Default Installation Options
VERBOSE_MODE="false"
UPDATE_APT="true"
INSTALL_APT_DEPS="true"
INSTALL_AVAHI="true"
INSTALL_YQ="true"
INSTALL_DOCKER="true"
INSTALL_DOCKER_COMPOSE="true"
INSTALL_CLOUDFLARED="true"
INSTALL_SSHX="true"
INSTALL_EDGEBOXCTL="true"
INSTALL_EDGEBOX_API="true"
INSTALL_EDGEBOX_WS="true"
INSTALL_EDGEBOX_APPS="true"
INSTALL_EDGEBOX_LOGGER="true"
INSTALL_EDGEBOX_UPDATER="true"
CREATE_USER="true"
ADD_MOTD="true"
AUTO_START="true"
INSTALL_PATH="/home/system/components"
EDGEBOX_SYSTEM_PW="edgebox"
EDGEBOX_CLUSTER_HOST=""

# Parse arguments
arguments=${@:-}

if [[ "${arguments}" = *"--verbose"* ]]
then
  VERBOSE_MODE="true"
fi

if [[ "${arguments}" = *"--no-install-avahi"* ]]
then
  INSTALL_AVAHI="false"
fi

if [[ "${arguments}" = *"--no-install-yq"* ]]
then
  INSTALL_YQ="false"
fi

if [[ "${arguments}" = *"--no-install-docker"* ]]
then
  INSTALL_DOCKER="false"
fi

if [[ "${arguments}" = *"--no-install-compose"* ]]
then
  INSTALL_DOCKER_COMPOSE="false"
fi

if [[ "${arguments}" = *"--no-install-cloudflared"* ]]
then
  INSTALL_CLOUDFLARED="false"
fi

if [[ "${arguments}" = *"--no-install-sshx"* ]]
then
  INSTALL_SSHX="false"
fi

if [[ "${arguments}" = *"--no-install-edgeboxctl"* ]]
then
  INSTALL_EDGEBOXCTL="false"
fi

if [[ "${arguments}" = *"--no-install-edgebox-api"* ]]
then
  INSTALL_EDGEBOX_API="false"
fi

if [[ "${arguments}" = *"--no-install-edgebox-ws"* ]]
then
  INSTALL_EDGEBOX_WS="false"
fi

if [[ "${arguments}" = *"--no-install-edgebox-apps"* ]]
then
  INSTALL_EDGEBOX_APPS="false"
fi

if [[ "${arguments}" = *"--no-install-edgebox-logger"* ]]
then
  INSTALL_EDGEBOX_LOGGER="false"
fi

if [[ "${arguments}" = *"--no-install-edgebox-updater"* ]]
then
  INSTALL_EDGEBOX_UPDATER="false"
fi

if [[ "${arguments}" = *"--no-create-user"* ]]
then
  CREATE_USER="false"
fi

if [[ "${arguments}" = *"--no-auto-start"* ]]
then
  AUTO_START="false"
fi

if [[ "${arguments}" = *"--no-add-motd"* ]]
then
  ADD_MOTD="false"
fi

if [[ "${arguments}" = *"--no-update-apt"* ]]
then
    UPDATE_APT="false"
fi

if [[ "${arguments}" = *"--no-install-deps"* ]]
then
  INSTALL_APT_DEPS="false"
  INSTALL_AVAHI="false"
  INSTALL_YQ="false"
  INSTALL_DOCKER="false"
  INSTALL_DOCKER_COMPOSE="false"
  INSTALL_CLOUDFLARED="false"
  INSTALL_SSHX="false"
fi

if [[ "${arguments}" = *"--no-install-components"* ]]
then
  INSTALL_EDGEBOXCTL="false"
  INSTALL_EDGEBOX_API="false"
  INSTALL_EDGEBOX_WS="false"
  INSTALL_EDGEBOX_APPS="false"
  INSTALL_EDGEBOX_LOGGER="false"
  INSTALL_EDGEBOX_UPDATER="false"
fi

if [[ "${arguments}" = *"--version"* ]]
then
    VERSION="$(echo "${arguments}" | sed 's/.*--version \([^ ]*\).*/\1/')"
fi

if [[ "${arguments}" = *"--install-path"* ]]
then
    INSTALL_PATH="$(echo "${arguments}" | sed 's/.*--install-path \([^ ]*\).*/\1/')"
fi

if [[ "${arguments}" = *"--system-password"* ]]
then
    EDGEBOX_SYSTEM_PW="$(echo "${arguments}" | sed 's/.*--system-password \([^ ]*\).*/\1/')"
    export EDGEBOX_SYSTEM_PW
fi

if [[ "${arguments}" = *"--cluster-host"* ]]
then
  EDGEBOX_CLUSTER_HOST="$(echo "${arguments}" | sed 's/.*--cluster-host \([^ ]*\).*/\1/')"
  export EDGEBOX_CLUSTER_HOST
fi

# Get current system architecture (and normalize to POSIX standard)
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    export ARCH="arm64"
fi

if [  "$ARCH" = "x86_64" ]; then
    export ARCH="amd64"
fi

if [  "$ARCH" = "armv7l" ]; then
    # Unsupported architecture. Error out.
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

create_user() {
    # Create user system and add to sudoers, set password to EDGEBOX_SYSTEM_PW
    useradd -m -s /bin/bash system || true
    echo "system:$(printenv EDGEBOX_SYSTEM_PW)" | chpasswd
    usermod -aG sudo system

    # Set root password as EDGEBOX_SYSTEM_PW
    echo "root:$(printenv EDGEBOX_SYSTEM_PW)" | chpasswd

    # Allow SSH access without public key
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

    # Allow root ssh login
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    systemctl restart ssh
}

update_apt() {
    sudo apt-get update --yes
}

install_apt_deps() {
    sudo apt-get install --yes python3-pip golang jq apache2-utils restic golang
}

install_avahi() {
    sudo apt-get install --yes avahi-daemon avahi-utils libnss-mdns
}

install_docker() {
    sudo apt-get install --yes docker.io
    # pip3 -v install docker==6.1.3
}

install_docker_compose() {
    sudo apt-get install --yes docker-compose
    # pip3 -v install docker-compose
}

install_yq() {
    # pip3 -v install yq
    sudo apt-get install --yes yq
}

install_cloudflared() {
    wget -q https://github.com/cloudflare/cloudflared/releases/download/2023.3.1/cloudflared-linux-$(printenv ARCH).deb
    sudo dpkg -i cloudflared-linux-$(printenv ARCH).deb
}

install_sshx() {
    curl -sSf https://sshx.io/get | sh
}

install_edgeboxctl() {
    cd $INSTALL_PATH
    git clone https://github.com/edgebox-iot/edgeboxctl.git || true
    # Setup cloud env and build edgeboxctl
    cd edgeboxctl
    # Check if the file /home/ubuntu/cloud.env exists. If it does, copy it to /home/system/components/api
    if [ -f /home/ubuntu/cloud.env ]; then
        cp /home/ubuntu/cloud.env /home/system/components/api/cloud.env
        make install-cloud
    else
        # Get curent system architecture
        ARCH=$(uname -m)
        if [ "$ARCH" = "aarch64" ]; then
            make install-arm64
        fi
        if [ "$ARCH" = "armv7l" ]; then
            make install-armhf
        fi
        if [ "$ARCH" = "x86_64" ]; then
            make install-amd64
        fi
    fi
}

install_edgebox_api() {
    cd $INSTALL_PATH
    git clone https://github.com/edgebox-iot/api.git || true

    if [ -n "${EDGEBOX_CLUSTER_HOST}" ]; then
        # build add cluster host to api conf
        # Configure Dashboard Host
        cd api
        touch myedgeapp.env
        echo "INTERNET_URL=$EDGEBOX_CLUSTER_HOST" >> myedgeapp.env
        cd ..
    fi
}

install_edgebox_ws() {
    cd $INSTALL_PATH
    git clone https://github.com/edgebox-iot/ws.git || true
    # Prep ws permissions
    cd ws
    chmod 757 ws
    mkdir -p appdata
    chmod -R 777 appdata
}

install_edgebox_apps() {
    cd $INSTALL_PATH
    git clone https://github.com/edgebox-iot/apps.git || true
}

install_edgebox_logger() {
    cd $INSTALL_PATH
    git clone https://github.com/edgebox-iot/logger.git || true
    cd logger
    make install
}

install_edgebox_updater() {
    cd $INSTALL_PATH
    git clone https://github.com/edgebox-iot/updater.git || true
}

start_services() {
    # Reload deamon, enable, and start services
    systemctl daemon-reload
    systemctl enable edgeboxctl
    systemctl start edgeboxctl
    systemctl enable logger
    systemctl start logger
    cd $INSTALL_PATH
    cd ws
    ./ws -b
}

add_motd() {
    # Create motd file
    cat << EOF > /etc/motd
            #######                                                             
        #############                                                          
    ########  #  #######                                                       
    ####   #######  #####    #####     ##               ##                     
    ####################     ####   #####  #####  ####  #####  #####  ## ##    
    ####################     ##     ## ##  #  ## #####  ##  #  ## ##   ###     
    ####  ########  #####    #####   ####  #####  ####  #####   ###   ## ##    
    #######   #  ########                   ###                                
        #############                                                          
            ########                                                             
                                                                                                
    You're connected to the Edgebox system via terminal. 
    This provides administrator capabilities and total system access.
    If you're developing for Edgebox, please refer to https://docs.edgebox.io

    This software comes with ABSOLUTELY NO WARRANTY, 
    to the extent permitted by applicable law.

EOF

    # add a line to print it on /root/.bashrc
    # Shoudl be automatic for Debian, but if not, just uncomment this line
    # echo "cat /etc/motd" >> /root/.bashrc

}

main() {

    cat << EOF

            #######                                                             
        #############                                                          
    ########  #  #######                                                       
    ####   #######  #####    #####     ##               ##                     
    ####################     ####   #####  #####  ####  #####  #####  ## ##    
    ####################     ##     ## ##  #  ## #####  ##  #  ## ##   ###     
    ####  ########  #####    #####   ####  #####  ####  #####   ###   ## ##    
    #######   #  ########                   ###                                
        #############                                                          
            ########                                                             

EOF

    echo "Edgebox is about to be installed in \"${INSTALL_PATH}\". 🚀"
    echo "If you want like to install in another location, you can specify a custom one with:"
    echo
    echo "  curl -L install.edgebox.io | bash -s -- --install-path /some/path"
    echo
    echo "Waiting for 10 seconds... 🕒"
    echo
    echo "You may press Ctrl+C now to abort the install."
    echo
    sleep 10

    if [[ "${CREATE_USER}" = "true" ]]
    then
        echo "-> 👤 Creating User..."
        sleep 3
        create_user
        
    fi

    echo "-> 📁 Creating Installation Path..."
    sleep 3
    # Create INSTALL_PATH directory if it doesn't exist
    mkdir -p $INSTALL_PATH || true
    

    if [[ "${UPDATE_APT}" = "true" ]]
    then
        echo "-> 🌳 Updating Operating System Packages..."
        sleep 3
        update_apt
        
    fi

    if [[ "${INSTALL_APT_DEPS}" = "true" ]]
    then
        echo "-> 🧰 Installing APT Dependencies..."
        sleep 3
        install_apt_deps
        
    fi

    if [[ "${INSTALL_AVAHI}" = "true" ]]
    then
        echo "-> 🔗 Installing mDNS..."
        sleep 3
        install_avahi
        
    fi

    if [[ "${INSTALL_YQ}" = "true" ]]
    then
        echo "-> 🧰 Installing YQ..."
        sleep 3
        install_yq
        
    fi

    if [[ "${INSTALL_DOCKER}" = "true" ]]
    then
        echo "-> 🐳 Installing Docker..."
        sleep 3
        install_docker
        
    fi

    if [[ "${INSTALL_DOCKER_COMPOSE}" = "true" ]]
    then
        echo "-> 🐳 Installing Docker Compose..."
        sleep 3
        install_docker_compose
        
    fi

    if [[ "${INSTALL_CLOUDFLARED}" = "true" ]]
    then
        echo "-> 🌐 Installing Cloudflared..."
        sleep 3
        install_cloudflared
        
    fi

    if [[ "${INSTALL_SSHX}" = "true" ]]
    then
        echo "-> 🔗 Installing SSHX..."
        sleep 3
        install_sshx
        
    fi

    if [[ "${INSTALL_EDGEBOXCTL}" = "true" ]]
    then
        echo "-> 📦 Installing Edgebox Service..."
        sleep 3
        install_edgeboxctl
        
    fi

    if [[ "${INSTALL_EDGEBOX_API}" = "true" ]]
    then
        echo "-> 💨 Installing Edgebox API / Dashboard..."
        sleep 3
        install_edgebox_api
        
    fi

    if [[ "${INSTALL_EDGEBOX_WS}" = "true" ]]
    then
        echo "-> 🕸️ Installing Edgebox Web Services..."
        sleep 3
        install_edgebox_ws
        
    fi

    if [[ "${INSTALL_EDGEBOX_APPS}" = "true" ]]
    then
        echo "-> 📱 Installing Edgebox Apps Repository..."
        sleep 3
        install_edgebox_apps
        
    fi

    if [[ "${INSTALL_EDGEBOX_LOGGER}" = "true" ]]
    then
        echo "-> 🪵 Installing Edgebox Logger..."
        sleep 3
        install_edgebox_logger
        
    fi

    if [[ "${INSTALL_EDGEBOX_UPDATER}" = "true" ]]
    then
        echo "-> 👇 Installing Edgebox Updater..."
        sleep 3
        install_edgebox_updater
        
    fi

    if [[ "${ADD_MOTD}" = "true" ]]
    then
        echo "-> 📟 Adding Console Welcome Message..."
        add_motd
    fi

    if [[ "${AUTO_START}" = "true" ]]
    then
        echo "-> 🏁 Starting Services... This can take a couple of minutes."
        sleep 3
        start_services
        
    fi

    echo "Edgebox has been successfully installed! 🎉"
    echo "You can now access the Dashboard by visiting: http://edgebox.local"
    echo "If you have any questions or need help, please visit https://docs.edgebox.io"
    echo
    echo "Thank you for using Edgebox! 🚀"
}

main
