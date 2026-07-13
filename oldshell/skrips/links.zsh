#!/bin/zsh

source ~/myshell/rc/linkdir/.zshrc

cd /root/myshell/rc/etc/zsh/

for X in $(l);do
ln -sb /root/myshell/rc/etc/zsh/$X ~Z/$X
done

ln -sb /root/myshell/rc/etc/nanorc /etc/nanorc

