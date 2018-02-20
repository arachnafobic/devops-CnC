#!/usr/bin/env bash

DISTRO=`lsb_release -cs`

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

exe "Setting up swapfile" \
     sh -c 'dd if=/dev/zero of=/swap bs=1024 count=2097152 && \
            mkswap /swap && chown root. /swap && chmod 0600 /swap && swapon /swap && \
            sh -c "echo /swap swap swap defaults 0 0 >> /etc/fstab" && \
            sh -c "echo vm.swappiness = 0 >> /etc/sysctl.conf && sysctl -p"'

# We use aptitude in precise (12.04) and trusty (14.04)
# The apt toolset in xenial (16.04) is superior though
if [ $DISTRO == "precise" ] || [ $DISTRO == "trusty" ]
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
else
  exe "Updating system" \
       sh -c 'export DEBIAN_FRONTEND=noninteractive && \
              apt update && \
              apt -y install squid-deb-proxy-client && \
              apt -y install git python-jinja2 python-setuptools python-yaml whois && \
              apt -y upgrade && \
              apt -y autoremove && \
              apt -y autoclean'
fi

if [[ $1 == "CnC" ]]
then
  exe "Preparing ansible 2.3.x" \
       sh -c 'mkdir -p /opt && \
              cd /opt && \
              git clone --recursive -b v2.3.3.0-1 https://github.com/ansible/ansible.git ansible-2.3.x && \
              ln -s ansible-2.3.x ansible && \
              chown -R vagrant.vagrant /opt/ansible/ && \
              chown -R vagrant.vagrant /opt/ansible-2.3.x/ && \
              echo "source /opt/ansible/hacking/env-setup 1>/dev/null 2>&1" >> /home/vagrant/.profile'
fi
