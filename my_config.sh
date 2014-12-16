#!/bin/bash
# Add any custom setup instructions here

export $HOME=/home/$BUGZILLA_USER

# Custom dependencies
$CPANM IPC::System::Simple
$CPANM App::Cmd
$CPANM File::Copy::Recursive
$CPANM Config::General
$CPANM Net::RabbitMQ
$CPANM GraphViz
$CPANM Pod::Checker
$CPANM REST::Client
$CPANM Test::WWW::Selenium
$CPANM JSON::RPC::Client

# Bugzilla dev manager configuration
git clone https://github.com/dklawren/bugzilla-dev-manager.git \
    -b app $HOME/devel/bugzilla-dev-manager
mkdir $HOME/devel/bin
ln -sf $HOME/devel/bugzilla-dev-manager/bz $HOME/devel/bin/bz
cp $HOME/devel/bugzilla-dev-manager/bz-dev.conf-sample \
    /etc/bz-dev.conf

# Home dotfiles
export HOME=/home/$BUGZILLA_USER
git clone https://github.com/dklawren/homedir $HOME/homedir
cd $HOME/homedir && ./makedotfiles.sh
ln -sf $HOME/devel/.bz-dev $HOME/.bz-dev

# Vim configuration
git clone https://github.com/dklawren/dotvim $HOME/.vim
cd $HOME/.vim
git submodule update --init
ln -sf $HOME/.vim/rc/vimrc $HOME/.vimrc
git clone https://github.com/powerline/fonts.git $HOME/powerline-fonts
cd $HOME/powerline-fonts && ./install.sh

# Permissions fixes
chmod 711 $HOME && chown -R $BUGZILLA_USER.$BUGZILLA_USER $HOME
