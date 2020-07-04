#!/usr/bin/env bash
# This script will auto-detect the OS and Version
# It will update system packages and install Ansible and git
# Then it will clone the hornet-playbook and run it.

# Hornet playbook: https://github.com/nuriel77/hornet-playbook
# By Nuriel Shem-Tov (https://github.com/nuriel77), December 2019
# Copyright (c) 2020 Nuriel Shem-Tov

# Some options can be passed via environment variables:
# SET_DEFAULTS="true"   ..... set default option selections
# SKIP_PASSWORD="true"  ..... skip user and password selection (sets defaults)
# SKIP_REBOOT="true"    ..... skip require reboot (except on selinux/centos)
# SKIP_CONFIRM="true"   ..... skip installer confirmation
# INSTALL_OPTIONS       ..... additional command line arguments to pass to ansible-playbook

set -o pipefail
set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as user root"
    echo "Please change to root using: 'sudo su -' and re-run the script"
    exit 1
fi

export NEWT_COLORS='
window=,
'

declare -g HORNET_PLAYBOOK_DIR="/opt/hornet-playbook"
declare -g INSTALLER_OVERRIDE_FILE="${HORNET_PLAYBOOK_DIR}/group_vars/all/z-installer-override.yml"
declare -g PLAYBOOK_LIGHT="false"

# Configurable install options passed to ansible-playbook command
: "${INSTALL_OPTIONS:=}"

# Set minimum ram, used to set light profile.
: "${MIN_RAM_KB:=2097152}"

if test -e /etc/motd && grep -q 'HORNET PLAYBOOK' /etc/motd; then
    :>/etc/motd
else
    if [ -f "$INSTALLER_OVERRIDE_FILE" ] && [[ "$1" != "rerun" ]] && [[ "$SKIP_CONFIRM" != true ]]
    then
        if ! (whiptail --title "Confirmation" \
                 --yesno "
It looks like a previous installation already exists.

Running the installer on an already working node is not recommended.
If you want to re-run only the playbook check the documentation or ask for assistance on Discord #fullnodes channel.

Please confirm you want to proceed with the installation?" \
                 --defaultno \
                 16 78); then
            exit 1
        fi
        SKIP_CONFIRM="true"
    fi
fi

clear
cat <<'EOF'

██╗  ██╗ ██████╗ ██████╗ ███╗   ██╗███████╗████████╗
██║  ██║██╔═══██╗██╔══██╗████╗  ██║██╔════╝╚══██╔══╝
███████║██║   ██║██████╔╝██╔██╗ ██║█████╗     ██║
██╔══██║██║   ██║██╔══██╗██║╚██╗██║██╔══╝     ██║
██║  ██║╚██████╔╝██║  ██║██║ ╚████║███████╗   ██║
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝

          _|                      _|                            _|
_|_|_|    _|    _|_|_|  _|    _|  _|_|_|      _|_|      _|_|    _|  _|
_|    _|  _|  _|    _|  _|    _|  _|    _|  _|    _|  _|    _|  _|_|
_|    _|  _|  _|    _|  _|    _|  _|    _|  _|    _|  _|    _|  _|  _|
_|_|_|    _|    _|_|_|    _|_|_|  _|_|_|      _|_|      _|_|    _|    _|
_|                            _|
_|                        _|_|

EOF

cat <<EOF
Welcome to HORNET IOTA FullNode Installer!
1. By pressing 'y' you agree to install the HORNET fullnode on your system.
2. By pressing 'y' you aknowledge that this installer requires a CLEAN operating system
   and may otherwise !!!BREAK!!! existing software on your server.
3. If you already have a configured server, re-running this script will overwrite previous configuration.

EOF

if [[ "$SKIP_CONFIRM" != true ]]
then
    read -p "Do you wish to proceed? [y/N] " yn
    if echo "$yn" | grep -v -iq "^y"; then
        echo Cancelled
        exit 1
    fi
fi

#################
### Functions ###
#################
function set_dist() {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        echo "Unsupported OS."
        exit 1
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        echo "Old OS version. Minimum required is 7."
        exit 1
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        VER=$(uname -r)
    fi
}

function wait_apt(){
    local i=0
    tput sc
    while fuser /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
        case $(($i % 4)) in
          0 ) j="-" ;;
          1 ) j="\\" ;;
          2 ) j="|" ;;
          3 ) j="/" ;;
        esac
        tput rc
        echo -en "\r[$j] System packages being updated to newest version, this can take a moment..."
        sleep 0.5
        ((i=i+1))
    done
    echo
}

function init_centos_7(){
    echo "Updating system packages..."
    yum update -y

    echo "Install epel-release..."
    yum install epel-release -y

    echo "Update epel packages..."
    yum update -y

    echo "Install yum utils..."
    yum install -y yum-utils

    set +e
    set +o pipefail
    if $(needs-restarting -r 2>&1 | grep -q "Reboot is required"); then
        [[ "$SKIP_REBOOT" != true ]] && { inform_reboot; exit 0; }
    fi
    set -o pipefail
    set -e

    echo "Installing Ansible and git..."
    yum install -y\
      ansible\
      redhat-lsb-core\
      git\
      expect-devel\
      cracklib\
      newt\
      python3\
      python3-pip
    if [ -e /usr/bin/pip ]; then
        /usr/bin/pip install jmespath
    fi
    if [ -e /usr/bin/pip3 ]; then
        /usr/bin/pip3 install jmespath
    fi
}

function init_centos_8(){
    echo "Updating system packages..."
    dnf update -y --nobest

    echo "Install epel-release..."
    dnf install epel-release -y

    echo "Update epel packages..."
    dnf update -y --nobest

    echo "Install yum utils..."
    dnf install -y yum-utils

    local OUTPUT=$(needs-restarting)
    if [[ "$OUTPUT" != "" ]]; then
        [[ "$SKIP_REBOOT" != true ]] && { inform_reboot; exit 0; }
    fi

    echo "Installing Ansible, git and other requirements..."
    dnf install -y\
      git\
      expect\
      newt\
      python3-pip\
      cracklib\
      redhat-lsb-core
    pip3 --disable-pip-version-check install ansible jmespath
    echo "$PATH" | grep -q '/usr/local/bin' || export PATH=$PATH:/usr/local/bin
    grep PATH /root/.bashrc | grep -q '/usr/local/bin' || echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bashrc
}

function init_ubuntu(){
    # We have to test a few times because apt is unexpected upon update
    # of many packages (especially during update of old node)
    wait_apt && echo "Ensuring no package managers ..." && sleep 5 && wait_apt

    echo "Updating system packages..."
    apt update -qqy --fix-missing
    apt-get upgrade -y
    apt-get clean
    apt-get autoremove -y --purge

    echo "Check reboot required..."
    if [ -f /var/run/reboot-required ]; then
        [[ "$SKIP_REBOOT" != true ]] && { inform_reboot; exit 0; }
    fi

    echo "Installing Ansible and git..."
    apt-get install software-properties-common -y
    # PPA not ready for ubuntu focal yet (20.04)
    [[ ! "$VER" =~ ^20 ]] && apt-add-repository ppa:ansible/ansible -y
    add-apt-repository universe -y
    apt-get update -y
    apt-get install ansible\
                    git\
                    expect-dev\
                    tcl\
                    libcrack2\
                    cracklib-runtime\
                    whiptail\
                    python3-pip -y

    [[ ! "$VER" =~ ^20 ]] && apt-get install python-pip -y

    if [ -e /usr/bin/pip ]; then
        /usr/bin/pip install jmespath
    fi
    if [ -e /usr/bin/pip3 ]; then
        /usr/bin/pip3 install jmespath
    fi
}

function init_debian(){
    # We have to test a few times because apt is unexpected upon update
    # of many packages (especially during update of old node)
    wait_apt && echo "Ensuring no package managers ..." && sleep 5 && wait_apt

    echo "Updating system packages..."
    apt update -qqy --fix-missing
    apt-get upgrade -y
    apt-get clean
    apt-get autoremove -y --purge

    echo "Check reboot required..."
    if [ -f /var/run/reboot-required ]; then
        [[ "$SKIP_REBOOT" != true ]] && { inform_reboot; exit 0; }
    fi

    echo "Installing Ansible and git..."
    local ANSIBLE_SOURCE="deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main"
    grep -q "$ANSIBLE_SOURCE" /etc/apt/sources.list || echo "$ANSIBLE_SOURCE" >> /etc/apt/sources.list
    apt-get install dirmngr --install-recommends -y
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
    apt-get update -y
    apt-get install ansible\
                    git\
                    less\
                    expect-dev\
                    tcl\
                    libcrack2\
                    cracklib-runtime\
                    whiptail\
                    lsb-release\
                    python3-pip\
                    python-pip \
                    python-backports.functools-lru-cache -y
    if [ -e /usr/bin/pip ]; then
        /usr/bin/pip install jmespath
    fi
    if [ -e /usr/bin/pip3 ]; then
        /usr/bin/pip3 install jmespath
    fi
}

function inform_reboot() {
    if [[ "$INSTALL_OPTIONS" =~ overwrite=yes ]]
    then
        cat <<EOF
===== Some packages installed require a reboot ======

Please reboot the node once the installation is done!

=====================================================
EOF
        return
    fi

    cat <<EOF >/etc/motd
======================== HORNET PLAYBOOK ========================

To proceed with the installation, please re-run:

bash <(curl -s https://raw.githubusercontent.com/nuriel77/hornet-playbook/master/fullnode_install.sh)

(make sure to run it as user root)

EOF

cat <<EOF


======================== PLEASE REBOOT AND RE-RUN THIS SCRIPT =========================

Some system packages have been updated which require a reboot
and allow the node installer to proceed with the installation.

*** Please reboot this machine and re-run this script ***


>>> To reboot run: 'reboot', and when the server is back online:
bash <(curl -s https://raw.githubusercontent.com/nuriel77/hornet-playbook/master/fullnode_install.sh)

!! Remember to run this command as user 'root' !!

EOF
}

function set_admin_password_a() {
    whiptail --title "Admin Password" \
             --passwordbox "
Please enter the password with which you will connect to services (IOTA Peer manager, Grafana, etc).

Use a stong password!!! Not 'hello123' or 'iota8181', you get the point ;).
Only valid ASCII characters are allowed." \
             10 78 3>&1 1>&2 2>&3

    if [[ $? -ne 0 ]]; then
        echo "Installation cancelled"
    fi
}

function set_admin_password_b() {
    whiptail --passwordbox "please repeat" 8 78 --title "Admin Password" 3>&1 1>&2 2>&3
    if [[ $? -ne 0 ]]; then
        echo "Installation cancelled"
    fi
}

function get_admin_password() {

    # Get first password and validate ascii characters only
    local PASSWORD_A=$(set_admin_password_a)
    if [[ "$PASSWORD_A" == "Installation cancelled" ]]; then
        echo "$PASSWORD_A"
        exit 1
    fi

    local LC_CTYPE=C
    case "${PASSWORD_A}" in
        *[![:cntrl:][:print:]]*)
            whiptail --title "Invalid characters!!" \
                     --msgbox "
Only ASCII characters are allowed:

!\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_\`abcdefghijklmnopqrstuvwxyz{|}~" \
                     12 78
            get_admin_password
            return
            ;;
    esac

    # Get password again and check passwords match
    local PASSWORD_B=$(set_admin_password_b)
    if [[ "$PASSWORD_B" == "Installation cancelled" ]]; then
        echo "$PASSWORD_B"
        exit 1
    fi
    if [ "$PASSWORD_A" != "$PASSWORD_B" ]; then
        whiptail --title "Passwords Mismatch!" \
                 --msgbox "Passwords do not match, please try again." \
                 8 78
        get_admin_password
        return
    fi

    PASSWD_CHECK=$(echo -n "$PASSWORD_A" | cracklib-check)
    if [[ $(echo "$PASSWD_CHECK" | awk {'print $2'}) != "OK" ]]; then
        whiptail --title "Weak Password!" \
                 --msgbox "Please choose a better password:$(echo ${PASSWD_CHECK}|cut -d: -f2-)" \
                 8 78
        get_admin_password
        return
    fi

    # Ensure we escape single quotes (using single quotes) because we need to
    # encapsulate the password with single quotes for the Ansible variable file
    PASSWORD_A=$(echo "${PASSWORD_A}" | sed "s/'/''/g")
    echo "fullnode_user_password: '${PASSWORD_A}'" >> "$INSTALLER_OVERRIDE_FILE"
    chmod 600 "$INSTALLER_OVERRIDE_FILE"
}

function set_admin_username() {
    ADMIN_USER=$(whiptail --inputbox "
Choose an administrator's username.
Only valid ASCII characters are allowed:" \
                 10 $WIDTH "$ADMIN_USER" \
                 --title "Choose Admin Username" 3>&1 1>&2 2>&3)
    if [[ $? -ne 0 ]]; then
        echo "Installation cancelled"
    fi

    local LC_CTYPE=C
    case "${ADMIN_USER}" in
        *[![:cntrl:][:print:]]*)
            whiptail --title "Invalid characters!!" \
                     --msgbox "
Only ASCII characters are allowed:

!\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_\`abcdefghijklmnopqrstuvwxyz{|}~" \
                     12 78
            set_admin_username
            return
            ;;
    esac

    echo "fullnode_user: '${ADMIN_USER}'" >> "$INSTALLER_OVERRIDE_FILE"

}

# Installation selection menu
function set_selections() {
    local RC RESULTS RESULTS_ARRAY CHOICE SKIP_TAGS
    SKIP_TAGS="--skip-tags=_"
    DISABLE_MONITORING_DEFAULT="ON"
    DISABLE_MONITORING_MSG=" (recommended)"

    if [[ "$PLAYBOOK_LIGHT" = true ]]
    then
        echo "hornet_profile: light" >>"$INSTALLER_OVERRIDE_FILE"
    elif [[ ! "$OS" =~ ^Raspbian ]]
    then
        DISABLE_MONITORING_DEFAULT="OFF"
        DISABLE_MONITORING_MSG=""
    fi

    RESULTS=$(whiptail --title "Installation Options" --checklist \
        --cancel-button "Exit" \
        "
Please choose additional installation options.
Note that defaults have been set according to your system's configuration.

Select/unselect options using space and click Enter to proceed.
        " 24 78 6 \
        "INSTALL_DOCKER"           "Install Docker runtime (recommended)" ON \
        "INSTALL_NGINX"            "Install nginx webserver (recommended)" ON \
        "SKIP_FIREWALL_CONFIG"     "Skip configuring firewall" OFF \
        "ENABLE_HAPROXY"           "Enable HAProxy (recommended)" ON \
        "DISABLE_MONITORING"       "Disable node monitoring${DISABLE_MONITORING_MSG}" "$DISABLE_MONITORING_DEFAULT" \
        "ENABLE_COMNET"            "Run this node on the comnet" OFF \
        3>&1 1>&2 2>&3)

    RC=$?
    if [[ $RC -ne 0 ]]; then
        echo "Installation cancelled"
        exit 1
    fi

    read -a RESULTS_ARRAY <<< "$RESULTS"
    for CHOICE in "${RESULTS_ARRAY[@]}"
    do
        case $CHOICE in
            '"INSTALL_DOCKER"')
                INSTALL_DOCKER="true"
                ;;
            '"INSTALL_NGINX"')
                INSTALL_NGINX="true"
                ;;
            '"SKIP_FIREWALL_CONFIG"')
                SKIP_FIREWALL_CONFIG="true"
                ;;
            '"DISABLE_MONITORING"')
                SKIP_TAGS+=",monitoring_role"
                DISABLE_MONITORING="true"
                ;;
            '"ENABLE_HAPROXY"')
                ENABLE_HAPROXY="true"
                ;;
            '"ENABLE_COMNET"')
                ENABLE_COMNET="true"
                ;;
            *)
                ;;
        esac
    done

    if [[ -n "$RESULTS" ]]; then
        RESULTS_MSG=$(echo "$RESULTS"|sed 's/ /\n/g')
        if ! (whiptail --title "Confirmation" \
                 --yesno "
You chose:

$RESULTS_MSG

Please confirm you want to proceed with the installation?" \
                 --defaultno \
                 16 78); then
            exit
        fi
    fi

    [ "$INSTALL_DOCKER" = true ] && echo "install_docker: true" >>"$INSTALLER_OVERRIDE_FILE"
    [ "$INSTALL_NGINX" = true ] && echo "install_nginx: true" >>"$INSTALLER_OVERRIDE_FILE"
    [ "$SKIP_FIREWALL_CONFIG" = true ] && echo "configure_firewall: false" >>"$INSTALLER_OVERRIDE_FILE"
    [ "$DISABLE_MONITORING" = true ] && echo "disable_monitoring: true" >>"$INSTALLER_OVERRIDE_FILE"
    [ "$ENABLE_HAPROXY" = true ] && echo "lb_bind_addresses: ['0.0.0.0']" >>"$INSTALLER_OVERRIDE_FILE"
    INSTALL_OPTIONS+=" $SKIP_TAGS"
}

function set_defaults() {
    cat <<EOF >>"$INSTALLER_OVERRIDE_FILE"
install_docker: true
install_nginx: true
configure_firewall: false
lb_bind_addresses: ['0.0.0.0']
EOF

    if [[ "$PLAYBOOK_LIGHT" = true ]] || [[ "$OS" =~ ^Raspbian ]]
    then
        echo "disable_monitoring: true" >>"$INSTALLER_OVERRIDE_FILE"
    fi
}

# Get primary IP from ICanHazIP, if it does not validate, fallback to local hostname
function set_primary_ip()
{
  echo "Getting external IP address..."
  local ip=$(curl -s -f --max-time 10 --retry 2 -4 'https://icanhazip.com')
  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
      echo "Got IP $ip"
      PRIMARY_IP=$ip
  else
      PRIMARY_IP=$(hostname -I|tr ' ' '\n'|head -1)
      echo "Failed to get external IP... using local IP $PRIMARY_IP instead"
  fi
}

function display_requirements_url() {
    echo "Only Debian, Ubuntu 18.04LTS, Ubuntu 19.x, Raspbian, CentOS 7 and 8 are supported."
}

function check_arch() {
    # Check architecture
    ARCH=$(uname -m)
    local REGEXP="x86_64|armv8l|aarch64"
    if [[ ! "$ARCH" =~ $REGEXP ]]; then
        echo "ERROR: $ARCH architecture not supported"
        display_requirements_url
        exit 1
    fi
}

function check_total_ram_min_kb() {
    MIN_RAM=$1
    MEM_TOTAL=$(grep ^MemTotal /proc/meminfo | awk {'print $2'})
    if [[ "$MEM_TOTAL" -gt "$MIN_RAM" ]]
    then
        return 1
    fi
}

function set_playbook_light() {
    PLAYBOOK_LIGHT="true"
}

function set_ssh_port() {
    SSH_PORT=$(whiptail --inputbox "
Please verify this is your active SSH port:" \
               8 78 \
               "$SSH_PORT" \
               --title "Verify SSH Port" 3>&1 1>&2 2>&3)
    if [[ $? -ne 0 ]] || [[ "$SSH_PORT" == "" ]]; then
        set_ssh_port
    elif [[ "$SSH_PORT" =~ [^0-9] ]] || [[ $SSH_PORT -gt 65535 ]] || [[ $SSH_PORT -lt 1 ]]; then
        whiptail --title "Invalid Input" \
                 --msgbox "Invalid input provided. Only numbers are allowed (1-65535)." \
                  8 78
        set_ssh_port
    fi
}

function skip_all_updates() {
    readarray -t TO_RUN_UPDATES < <(find "${HORNET_PLAYBOOK_DIR}/custom_updates/" -maxdepth 1 -type f -name '*_updates.sh')

    # Return if nothing to update
    ((${#TO_RUN_UPDATES[@]} == 0)) && { clear; return; }

    for FILE in "${TO_RUN_UPDATES[@]}"
    do
        touch "${FILE}.completed"
    done
}

function run_playbook(){
    # Get default SSH port
    set +o pipefail
    SSH_PORT=$(grep ^Port /etc/ssh/sshd_config | awk {'print $2'})
    set -o pipefail
    if [[ "$SSH_PORT" != "" ]] && [[ "$SSH_PORT" != "22" ]]; then
        set_ssh_port
    else
        SSH_PORT=22
    fi
    echo "SSH port to use: $SSH_PORT"

    # Ansible output log file
    LOGFILE="/var/log/hornet-playbook-$(date +%Y%m%d%H%M).log"

    # Enable comnet if selected
    [ "$ENABLE_COMNET" = true ] && cp -- "/opt/hornet-playbook/roles/shared-files/comnet-vars.yml" "/opt/hornet-playbook/group_vars/all/z-comnet-vars.yml"

    # Override ssh_port
    [[ $SSH_PORT -ne 22 ]] && echo "ssh_port: \"${SSH_PORT}\"" > "${HORNET_PLAYBOOK_DIR}/group_vars/all/z-ssh-port.yml"

    # Run the playbook
    echo "*** Running playbook command: ansible-playbook -i inventory -v site.yml -e "memory_autoset=true" $INSTALL_OPTIONS" | tee -a "$LOGFILE"
    set +e
    unbuffer ansible-playbook -i inventory -v site.yml -e "memory_autoset=true" $INSTALL_OPTIONS | tee -a "$LOGFILE"
    RC=$?
    if [ $RC -ne 0 ]; then
        echo "ERROR! The playbook exited with failure(s). A log has been save here '$LOGFILE'"
        exit $RC
    fi
    set -e

    # Check playbook needs reboot
    if [ -f "/var/run/playbook_reboot_hornet" ]; then
        cat <<EOF >/etc/motd
-------------------- HORNET PLAYBOOK --------------------

It seems you have rebooted the node. You can proceed with
the installation by running the command:

${HORNET_PLAYBOOK_DIR}/rerun.sh

(make sure you are user root!)

-------------------- HORNET PLAYBOOK --------------------
EOF

        cat <<EOF
-------------------- NOTE --------------------

The installer detected that the server requires a reboot,
most probably to enable a functionality required for the playbook.

You can reboot the server using the command 'reboot'.

Once the server is back online you can use the following command
to proceed with the installation (become user root first):

${HORNET_PLAYBOOK_DIR}/rerun.sh

-------------------- NOTE --------------------

EOF

        rm -f "/var/run/playbook_reboot_hornet"
        exit
    fi

    # Calling set_primary_ip
    set_primary_ip

    # Get configured username if missing.
    # This could happen on script re-run
    # due to reboot, therefore the variable is empty
    if [ -z "$ADMIN_USER" ]; then
        ADMIN_USER=$(grep "^fullnode_user:" "$INSTALLER_OVERRIDE_FILE" | awk {'print $2'})
    fi

    if ! grep -q "^disable_monitoring: true" "$INSTALLER_OVERRIDE_FILE"; then
        MONITORING_MSG=" and Grafana"
        MONITORING_URL=" and https://${PRIMARY_IP}:5555"
    fi

    OUTPUT=$(cat <<EOF
* A log of this installation has been saved to: $LOGFILE

* You should be able to connect to Hornet Dashboard${MONITORING_MS}:

https://${PRIMARY_IP}:8081${MONITORING_URL}

* Note that your IP might be different as this one has been auto-detected in best-effort.

* Log in with username ${ADMIN_USER} and the password you have entered during the installation.

Thank you for installing an IOTA node with the hornet-playbook!

EOF
)

    HEIGHT=$(expr $(echo "$OUTPUT"|wc -l) + 10)
    whiptail --title "Installation Done" \
             --msgbox "$OUTPUT" \
             $HEIGHT 78
}

#####################
### End Functions ###
#####################

# Incase we call a re-run
if [[ -n "$1" ]] && [[ "$1" == "rerun" ]]; then
    run_playbook
    exit
fi

### Get OS and version
set_dist

# Check OS version compatibility
if [[ "$OS" =~ ^(CentOS|Red) ]]; then
    if [[ ! "$VER" =~ ^(7|8) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_centos_$VER
elif [[ "$OS" =~ ^Ubuntu ]]; then
    if [[ ! "$VER" =~ ^(16|17|18|19|20) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_ubuntu
elif [[ "$OS" =~ ^Debian ]]; then
    if [[ ! "$VER" =~ ^(9|10) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_debian
elif [[ "$OS" =~ ^Raspbian ]]; then
    if [[ ! "$VER" =~ ^(9|10) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch

    # Workaround to make sure we detect
    # if reboot is needed
    apt install unattended-upgrades -y

    # Same setup for respbian as debian
    init_debian

    # remove workaround
    apt remove unattended-upgrades -y
else
    echo "$OS not supported"
    exit 1
fi

echo "Verifying Ansible version..."
ANSIBLE_VERSION=$(ansible --version|head -1|awk {'print $2'}|cut -d. -f1-2)
if (( $(awk 'BEGIN {print ("'2.8'" > "'$ANSIBLE_VERSION'")}') )); then
    cat <<EOF
Error: Ansible minimum version 2.8 required.
Please remove Ansible: (yum remove ansible -y for CentOS, or apt-get remove -y ansible for Ubuntu).

Then refer to the documentation on how to get latest Ansible installed.
http://docs.ansible.com/ansible/latest/intro_installation.html
Note that for CentOS you may need to install Ansible from Epel to get version 2.8 or higher.
EOF
    exit 1
fi

echo "Git cloning hornet-playbook repository..."
cd /opt

# Backup any existing hornet-playbook directory
if [ -d hornet-playbook ]; then
    echo "Backing up older hornet-playbook directory..."
    rm -rf hornet-playbook.backup
    mv -- hornet-playbook "hornet-playbook.backup.$(date +%s)"
fi

# Clone the repository (optional branch)
git clone $GIT_OPTIONS https://github.com/nuriel77/hornet-playbook.git
cd "${HORNET_PLAYBOOK_DIR}"

# first installation? Skip all upgrades
skip_all_updates

if check_total_ram_min_kb "$MIN_RAM_KB"
then
    set_playbook_light
fi

# Let user choose installation add-ons or set defaults
if [[ "$SET_DEFAULTS" = true ]]
then
    set_defaults
else
    set_selections
fi

if [[ "$SKIP_PASSWORD" != true ]]
then
    # Get the administrators username
    set_admin_username

    # web access (ipm, haproxy, grafana, etc)
    get_admin_password
fi

echo -e "\nRunning playbook..."
run_playbook
