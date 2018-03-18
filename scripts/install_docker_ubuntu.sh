#!/bin/bash

###############################################################
# Installer for Docker Community Edition on an Ubuntu machine #
# This script follows the instructions given at               #
# https://docs.docker.com/engine/installation/linux/ubuntu/   #
###############################################################

DOCKER_GPG_ID="0EBFCD88"
DOCKER_GPG_FINGERPRINT="9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88"
DOCKER_KEYSERVER="https://download.docker.com/linux/ubuntu/gpg"
DOCKER_DOWNLOAD_URL="https://download.docker.com/linux/ubuntu"
DOCKER_VERSION=$1

usage() {
    echo "Usage: `basename $0` [-h] [VERSION]"
    echo "Install Docker on an Ubuntu machine by adding the official Docker repo"
    echo "to the apt repositories. If no VERSION is passed, the latest version of"
    echo "Docker will be installed by default."
    echo "Example: `basename $0` 17.03.1"
    echo "Options:"
    echo "    -h  print this message and exit"
    exit 85
}

while getopts ":h" opt; do
    case "$opt" in
        h )
            usage
            ;;
        * )
            continue
            ;;
    esac
done


#########################################
# helper functions
#########################################

VER_PATTERN='[0-9]{1,2}(\.[0-9]{1,2})+'
GPG_FINGERPRINT_PATTERN='([0-9A-F]{4}\s+){9}[0-9A-F]{4}'

get_ver_str () {
    if [[ ! -z $3 ]]; then
        local VER_PATTERN=$3
    fi
    read -r -a VER <<< $(echo "$1" | grep -E "$VER_PATTERN" -o)
    echo ${VER}
}

ver_comp () {
    if [[ $1 == $2 ]]; then
        echo "="
        return 0
    fi
    local IFS='.'
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 and ver2 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=${#ver2[@]}; i<${#ver1[@]}; i++)); do
        ver2[i]=0
    done
    #echo >&2 "ver1 is ${ver1[@]}"
    #echo >&2 "ver2 is ${ver2[@]}"

    local ops=("<" ">")
    for ((i=0; i<${#ver1[@]}; i++)); do
        for op in ${ops[@]}; do
            if (( ${ver1[i]} $op ${ver2[i]} )); then
                echo $op
                return 0
            fi
        done
    done
    echo "="
    return 0
}

ver_prefix() {
    local n=$2
    local IFS='.'
    local ver=($1)
    echo "${ver[*]:0:$n}";
}

legal_ver_str() {
    local ver_str=$1
    local ver_match=$(get_ver_str $1)
    if [[ $ver_str == $ver_match ]]; then
        return 0
    else
        return 1
    fi
}

install_trusty_extras() {
    echo "Installing linux-image-extra packages for Ubuntu 14.04 Trusty"
    echo "Running apt-get update"
    apt-get update
    apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual
}

verify_apt_key() {
    local keyid=$1
    local fingerprint=$2
    local fingerprint_info="$(apt-key export $keyid | gpg --with-fingerprint)"
    echo "GPG fingerprint output:"
    echo "$fingerprint_info"
    
    local IFS='
'
    for line in ${fingerprint_info[@]}; do
        if echo $line | grep -q -e "Key fingerprint = "; then
            local test_fingerprint="$(echo $line | grep -E $GPG_FINGERPRINT_PATTERN -o)"
            if [[ $test_fingerprint == $fingerprint ]]; then
                echo "Fingerprint matches '$fingerprint'; continuing"
                return
            else
                echo "Fingerprint"
                echo "'$test_fingerprint'"
                echo "does not match official fingerprint"
                echo "'$fingerprint'"
                echo "exiting"
                #exit 1
            fi
        fi
    done
}


#######################################
# Only run if the OS is Ubuntu        #
#######################################

linux_desc="$(lsb_release -d)"

if ! echo "$linux_desc" | grep -q Ubuntu; then
    echo "This script is designed for use with an Ubuntu OS; exiting."
    exit 1
fi

echo
echo

##############################################################
# Verify that input docker version is a legal version string #
##############################################################

if [[ -z $DOCKER_VERSION ]]; then
    if ! legal_ver_str $DOCKER_VERSION; then
        echo "'$DOCKER_VERSION' does not appear to be a legal version string; exiting"
        exit 1
    fi
fi

echo
echo

#######################################
# Uninstall older versions if present #
#######################################

if [[ ! -z $(which docker) ]]; then
    OLD_DOCKER_VERSION=$(get_ver_str "$(docker --version)")
    echo "Removing older docker version $OLD_DOCKER_VERSION"
    apt-get remove docker docker-engine
fi

echo
echo

#####################################################################################
# detect Ubuntu version and install recommended dependencies for that version first #
#####################################################################################

UBUNTU_VERSION=$(get_ver_str "$(lsb_release -r)")
UBUNTU_NICKNAME=$(lsb_release -cs)

if [[ $(ver_prefix $UBUNTU_VERSION 2) == "14.04" ]]; then
    install_trusty_extras
fi

echo
echo

########################################################################
# install necessary packages for allowing apt to use a repo over HTTPS #
########################################################################

echo "Installing apt-transport-https, ca-certificates, curl, and software-properties-common"
echo "to allow apt to use a repository over HTTPS"

apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

echo
echo

#################################
# add docker's official GPG key #
#################################

echo "Getting Docker's official GPG key"
if ! curl -fsSL $DOCKER_KEYSERVER | sudo apt-key add -; then
    echo "Problem adding docker key from $DOCKER_KEYSERVER; exiting"
    exit 1
fi

echo "Verifying that the public key's fingerprint matches $DOCKER_GPG_FINGERPRINT"
verify_apt_key $DOCKER_GPG_ID "$DOCKER_GPG_FINGERPRINT"

echo
echo

#################################
# Set up stable repository      #
#################################

sudo add-apt-repository "deb [arch=amd64]  $DOCKER_DOWNLOAD_URL $UBUNTU_NICKNAME stable"

echo
echo

#####################
# Install Docker    #
#####################

echo "Running apt-get update"
apt-get update

echo
echo

if [[ -z $DOCKER_VERSION ]]; then
    echo "Installing latest stable version of Docker from apt repository"
    if ! apt-get install docker-ce; then
        echo "Problem installing latest version of Docker; exiting"
        exit 1
    fi
else
    echo "Attempting to install Docker version $DOCKER_VERSION from apt repository"
    if ! apt-get install docker-ce=$DOCKER_VERSION; then
        echo "Problem installing Docker $DOCKER_VERSION; exiting"
        exit 1
    fi
fi

echo
echo

INSTALLED_VERSION=$(get_ver_str "$(docker --version)")
echo "Docker version $INSTALLED_VERSION has been successfully installed; exiting"

exit 0

