#!/bin/bash -ex
awk=`which awk`
while read line  
do
  user=`echo $line |$awk -F ":" '{print $1}'`;
  pkey=`echo $line |$awk -F ":" '{print $2}'`;
  if [ "x`grep -c $user /etc/passwd`" == "x0" ]; then
    echo "add user $user"
    `which useradd` $user -p '<#your password#>'
    chsh -s `which bash` $user

    if [ "x`grep -c $user /etc/sudoers`" == "x0" ]; then
      echo "add user to sudo list"
      echo "$user  ALL=(ALL) ALL" >> /etc/sudoers;
      #echo "$user  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers;
    fi
    mkdir -p /home/$user/.ssh && echo $pkey > /home/$user/.ssh/authorized_keys
    find /etc/skel/ -type f -exec cp {} /home/$user/ \;
    chmod -R 700 /home/$user/.ssh
    chown -R ${user}:users /home/$user
    echo "add user $user done"  
  fi
done < $ATTACH_DIR/user.list
