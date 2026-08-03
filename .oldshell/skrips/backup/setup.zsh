#!/bin/zsh

MYSH=${MYSH:-$HOME/myshell}

[[ ${*:l} =~ '(g|a)' ]]&&{ $MYSH/scripts/gitinstall }
[[ ${*:l} =~ '(s|c)' ]]&&{ git clone https://www.github.com/syl20bnr/spacemacs ~/.emacs.d }

cd $MYSH/prog
for X in $(ls -A);cp $X /bin;

cd $MYSH/rc/etc/zsh;
mv /etc/zsh /etc/zsh.bckp &>/dev/null;
ln -sb $PWD /etc/zsh;

cd ..;
ln -sb $PWD/nanorc /etc

cd $MYSH/rc/linkdir
ln -sb $PWD/.zshrc ~;
[[ $* =~ '(e|a)' ]] && ln -sb $PWD/.emacs ~;
[[ $* =~ '([sa[^e])' ]] && ln -sb $PWD/.spacemacs ~;

cd $MYSH;
ln -sb $PWD/workspace ~

return 0;
ln -si $MYSH/rc/linkdir/.xinitprofiles/xterm-client /etc/X11/xinit/xinitrc
