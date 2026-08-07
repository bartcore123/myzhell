#!/bin/zsh

cd ${MYSHELL:-$HOME/myshell}
hash -d M=$PWD
source ./rc/zshrc/nd
source ./rc/zshrc/opt

cd ~

[[ .zshrc ]] && mv -i .zshrc .zshrc.old
[[ .nanorc ]] && mv -i .nanorc .nanorc.old
[[ (|.)zsh-syntax-highlighting ]] || git clone https://github.com/zsh-users/zsh-syntax-highlighting .zsh-syntax-highlighting
[[ $ZSH ]] || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

[[ .zshrc ]] && mv .zshrc .zshrc.omz.bak

ln -s ./myshell/rc/ln/.nanorc
ln -s ./myshell/rc/ln/.zshrc

source .zshrc
