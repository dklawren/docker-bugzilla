#!/bin/bash

BUGZILLA_HOME="/home/$BUGZILLA_USER/devel/htdocs/bugzilla"
CPANM="cpanm --quiet --notest --skip-installed"

# Clone the code repo
git clone $BUGZILLA_REPO -b $BUGZILLA_BRANCH $BUGZILLA_HOME

# Install dependencies
cd $BUGZILLA_HOME
$CPANM DateTime
$CPANM Module::Build
$CPANM Software::License
$CPANM Pod::Coverage
$CPANM DBD::mysql
$CPANM Cache::Memcached::GetParserXS
$CPANM XMLRPC::Lite
$CPANM --installdeps --with-recommends .

# Configure bugs database
/usr/bin/mysqld_safe &
sleep 5
mysql -u root mysql -e "GRANT ALL PRIVILEGES ON *.* TO bugs@localhost IDENTIFIED BY 'bugs'; FLUSH PRIVILEGES;"
perl checksetup.pl /checksetup_answers.txt
mysqladmin -u root shutdown
