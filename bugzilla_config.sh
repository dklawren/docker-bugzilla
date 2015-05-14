#!/bin/bash

cd $BUGZILLA_HOME

# Install Perl dependencies
CPANM="cpanm --quiet --notest --skip-satisfied"

if [ "$GITHUB_BASE_BRANCH" == "master" ]; then
    perl checksetup.pl --cpanfile
    $CPANM --installdeps --with-recommends --with-all-features \
        --without-feature oracle --without-feature sqlite --without-feature pg .
else
    # Some modules are explicitly installed due to strange dependency issues
    $CPANM Software::License
    $CPANM HTML::FormatText::WithLinks
    $CPANM DBD::mysql
    $CPANM --installdeps --with-recommends .
fi

# For testing support
$CPANM Test::WWW::Selenium
$CPANM Pod::Coverage
$CPANM Pod::Checker

# Remove CPAN build files to minimize disk usage
rm -rf /root/.cpanm

# Configure database
/usr/bin/mysqld_safe &
sleep 5
mysql -u root mysql -e "GRANT ALL PRIVILEGES ON *.* TO bugs@localhost IDENTIFIED BY 'bugs'; FLUSH PRIVILEGES;"
mysql -u root mysql -e "CREATE DATABASE bugs CHARACTER SET = 'utf8';"
perl checksetup.pl /checksetup_answers.txt
perl checksetup.pl /checksetup_answers.txt
mysqladmin -u root shutdown
