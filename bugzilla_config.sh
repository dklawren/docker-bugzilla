#!/bin/bash

cd $BUGZILLA_HOME

# Install Perl dependencies
CPANM="cpanm --quiet --notest --skip-satisfied"

# Force version due to problem with CentOS ImageMagick-devel
$CPANM Image::Magick@6.77

perl checksetup.pl --cpanfile
$CPANM --installdeps --with-recommends --with-all-features \
    --without-feature oracle --without-feature sqlite --without-feature pg .

# These are not picked up by cpanm --with-all-features for some reason
$CPANM Template::Plugin::GD::Image
$CPANM MIME::Parser
$CPANM SOAP::Lite
$CPANM JSON::RPC
$CPANM Email::MIME::Attachment::Stripper
$CPANM TheSchwartz
$CPANM Text::MultiMarkdown
$CPANM XMLRPC::Lite

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

cd $BUGZILLA_HOME
perl checksetup.pl /checksetup_answers.txt
perl checksetup.pl /checksetup_answers.txt
perl /generate_bmo_data.pl
mysqladmin -u root shutdown
