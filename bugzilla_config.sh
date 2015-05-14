#!/bin/bash

cd $BUGZILLA_HOME

# Install Perl dependencies
CPANM="cpanm --quiet --notest --skip-satisfied"

$CPANM File::Slurp # Needed for checksetup to run - Bug 1163248
perl checksetup.pl --cpanfile
$CPANM --installdeps --with-recommends --with-all-features \
    --without-feature oracle --without-feature sqlite --without-feature pg .

# For testing support
$CPANM Test::WWW::Selenium
$CPANM Pod::Coverage
$CPANM Pod::Checker

# Configure database
/usr/bin/mysqld_safe &
sleep 5
mysql -u root mysql -e "GRANT ALL PRIVILEGES ON *.* TO bugs@localhost IDENTIFIED BY 'bugs'; FLUSH PRIVILEGES;"
mysql -u root mysql -e "CREATE DATABASE bugs CHARACTER SET = 'utf8';"

cd $BUGZILLA_HOME
perl checksetup.pl /checksetup_answers.txt
perl checksetup.pl /checksetup_answers.txt
perl /generate_bmo_data.pl

mysqladmin -u root shutdown
