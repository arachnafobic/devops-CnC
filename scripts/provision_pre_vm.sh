#!/usr/bin/env bash

exe () {
    # MESSAGE_PREFIX="\b\b\b\b\b\b\b\b\b\b"
    MESSAGE_PREFIX=""
    echo -e "$MESSAGE_PREFIX Execute: $1"
    LOOP=0
    while true;
    do
        # if ! [ $LOOP == 0 ]; then echo -e "$MESSAGE_PREFIX ...     "; fi;
        sleep 3;
        LOOP=$((LOOP+1))
    done & ERROR=$("${@:2}" 2>&1)
    status=$?
    kill $!; trap 'kill $!' SIGTERM

    if [ $status -ne 0 ];
    then
        echo -e "$MESSAGE_PREFIX ✖ Error" >&2
        echo -e "$ERROR" >&2
    else
        echo -e "$MESSAGE_PREFIX ✔ Success"
    fi
    return $status
}

# Detect distro and version used.
DISTRO=`cat /etc/os-release | grep ^NAME= | awk -F'=' '{print $2}' | awk -F '"' '{print $2}'`
VERSION=`cat /etc/os-release | grep ^VERSION_ID= | awk -F'=' '{print $2}' | awk -F '"' '{print $2}'`

if [ ! -e /swap ]; then
  exe "Setting up swapfile" \
       sh -c 'dd if=/dev/zero of=/swap bs=1024 count=2097152 && \
              mkswap /swap && chown root. /swap && chmod 0600 /swap && swapon /swap && \
              sh -c "echo /swap swap swap defaults 0 0 >> /etc/fstab" && \
              sh -c "echo vm.swappiness = 0 >> /etc/sysctl.conf && sysctl -p"'
fi

if [[ $DISTRO == "CloudLinux" ]]
then
  # vagrant/box specific workaround
  exe "Fixing ifcfg-eth0" \
       sh -c 'cp -f /home/vagrant/shared/clinux-ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0'
fi

# We use aptitude in precise (12.04) and trusty (14.04)
# The apt toolset in xenial (16.04) is superior though
if [[ $DISTRO == "Ubuntu" ]] && ( [[ $VERSION == "12.04" ]] || [[ $VERSION == "14.04" ]])
then
  exe "Adding aptitude for 12.04/14.04" \
       sh -c 'apt-get update && \
              apt-get -y install aptitude'

  exe "Updating system" \
       sh -c 'export DEBIAN_FRONTEND=noninteractive && \
              aptitude update && \
              aptitude -y install squid-deb-proxy-client && \
              aptitude -y install git python-jinja2 python-setuptools whois && \
              aptitude -y safe-upgrade && \
              aptitude -y autoclean'
elif [[ $DISTRO == "Ubuntu" ]] && ( [[ $VERSION != "12.04" ]] && [[ $VERSION != "14.04" ]])
then
  exe "Updating system" \
       sh -c 'export DEBIAN_FRONTEND=noninteractive && \
              apt update && \
              apt -y install squid-deb-proxy-client && \
              apt -y install git python-jinja2 python-setuptools python-yaml whois && \
              apt -y --with-new-pkgs --autoremove upgrade && \
              apt -y autoclean'
elif [[ $DISTRO == "CloudLinux" ]] || [[ $DISTRO == "CentOS Linux" ]]
then
#  grep "proxy" /etc/yum.conf
#  if [[ $? -ne 0 ]]
#  then
#    exe "Set yum proxy to 172.28.128.1:3128" \
#         sh -c 'echo "proxy=http://172.28.128.1:3128" >> /etc/yum.conf'
#  fi

  # update only works with valid license allready in place for cloudlinux
  if [[ $DISTRO == "CentOS Linux" ]]
  then
    exe "Updating system" \
         sh -c 'yum -q -y update'
  fi

else
  echo "Unknown distro/version combo detected, skipping auto update"
fi

if [[ $1 == "CnC" ]]
then
  if [ ! -d /opt/ansible/ ]; then
    exe "Preparing ansible 2.5.x" \
         sh -c 'mkdir -p /opt && \
                cd /opt && \
                git clone --recursive -b v2.5.4 https://github.com/ansible/ansible.git ansible-2.5.x && \
                ln -s ansible-2.5.x ansible && \
                chown -R vagrant.vagrant /opt/ansible/ && \
                chown -R vagrant.vagrant /opt/ansible-2.5.x/ && \
                echo "source /opt/ansible/hacking/env-setup 1>/dev/null 2>&1" >> /home/vagrant/.profile'
  fi
fi
