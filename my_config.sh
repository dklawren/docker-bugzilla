#!/bin/bash
# Add any custom setup instructions here

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
    -b app /home/$BUGZILLA_USER/devel/bugzilla-dev-manager
mkdir /home/$BUGZILLA_USER/devel/bin
ln -sf /home/$BUGZILLA_USER/devel/bugzilla-dev-manager/bz \
    /home/$BUGZILLA_USER/devel/bin/bz
cp /home/$BUGZILLA_USER/devel/bugzilla-dev-manager/bz-dev.conf-sample \
    /etc/bz-dev.conf

# Home dotfiles
export HOME=/home/$BUGZILLA_USER
git clone https://github.com/dklawren/homedir \
    /home/$BUGZILLA_USER/homedir
cd /home/$BUGZILLA_USER/homedir
./makedotfiles.sh
ln -sf /home/$BUGZILLA_USER/devel/.bz-dev /home/$BUGZILLA_USER/.bz-dev

chmod 711 /home/$BUGZILLA_USER
chown -R $BUGZILLA_USER.$BUGZILLA_USER /home/$BUGZILLA_USER
