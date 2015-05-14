#!/bin/bash

cd $BUGZILLA_HOME

# Install Perl dependencies
CPANM="cpanm --quiet --notest --skip-satisfied"

if [ "$GITHUB_BASE_BRANCH" == "master" ]; then
    perl checksetup.pl --cpanfile
    $CPANM --installdeps --with-recommends --with-all-features \
        --without-feature oracle --without-feature sqlite --without-feature mysql .
else
    # Some modules are explicitly installed due to strange dependency issues
    $CPANM Software::License
    $CPANM HTML::FormatText::WithLinks
    $CPANM DBD::Pg
    $CPANM --installdeps --with-recommends .
fi

# For testing support
$CPANM Test::WWW::Selenium
$CPANM Pod::Coverage
$CPANM Pod::Checker

# Remove CPAN build files to minimize disk usage
rm -rf /root/.cpanm

# Configure database
su postgres -c "/usr/bin/pg_ctl -D /var/lib/pgsql/data start" && sleep 5
su postgres -c "createuser --superuser bugs"
su postgres -c "psql -U postgres -d postgres -c \"alter user bugs with password 'bugs';\""
perl checksetup.pl /checksetup_answers.txt
perl checksetup.pl /checksetup_answers.txt
su postgres -c "/usr/bin/pg_ctl -D /var/lib/pgsql/data stop"
