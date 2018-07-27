#!/usr/bin/env bash

exe () {
    # MESSAGE_PREFIX="\b\b\b\b\b\b\b\b\b\b"
    MESSAGE_PREFIX=""
    echo -e "$MESSAGE_PREFIX    $VM:  Execute: $1"
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
        echo -e "$MESSAGE_PREFIX    $VM:  ✖ Error" >&2
        echo -e "$ERROR" >&2
    else
        echo -e "$MESSAGE_PREFIX    $VM:  ✔ Success"
    fi
    return $status
}

VM=$1

exe "fetching ssh-config" \
     sh -c "vagrant ssh-config $1 > .ssh-config.$1"

if [ ! -e shared/clinux-ifcfg-eth0 ]; then
  exe "placing a few premade configs into shared" \
       sh -c "cp -f files/clinux-ifcfg-eth0 shared/clinux-ifcfg-eth0"
fi

if [[ $1 == "CnC" ]]
then
  if [ -e ~/.bash_aliases ]; then
    exe "copying local ~/.bash_aliasses" \
         cp -f ~/.bash_aliases shared/profile_aliases
  fi

  if [ -n "`git config --get user.name`" ]; then
    exe "dumping git user name" \
         sh -c "git config --get user.name > shared/git_user"
  else
    exe "using whoami as git user name" \
         sh -c "whoami > shared/git_user"
  fi

  if [ -n "`git config --get user.email`" ]; then
    exe "dumping git user email" \
         sh -c "git config --get user.email > shared/git_email"
  else
    exe "using whoami to generate git user email" \
         sh -c 'echo "`whoami`@example.com" > shared/git_email'
  fi

  exe "fix permissions on dumped gitinfo" \
       chmod 644 shared/git_user shared/git_email
fi
