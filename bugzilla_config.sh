#!/bin/bash

BUGZILLA_HOME="/home/$BUGZILLA_USER/devel/htdocs/bugzilla"
CPANM="cpanm --quiet --notest --skip-installed"

# Clone the code repo
git clone $BUGZILLA_REPO -b $BUGZILLA_BRANCH $BUGZILLA_HOME

# Install Perl dependencies
# Some modules are explicitly installed due to strange dependency issues
curl -L http://cpanmin.us | perl - --sudo App::cpanminus
cd $BUGZILLA_HOME
$CPANM DBD::mysql
$CPANM Apache2::SizeLimit
$CPANM HTTP::Tiny
$CPANM HTML::TreeBuilder
$CPANM HTML::Element
$CPANM HTML::FormatText
$CPANM Apache2::SizeLimit
$CPANM --installdeps --with-recommends .

# Some Apache config tweaks
sed -e "s?User apache?User $BUGZILLA_USER?g" --in-place /etc/httpd/conf/httpd.conf
sed -e "s?Group apache?Group $BUGZILLA_USER?g" --in-place /etc/httpd/conf/httpd.conf

# Configure bugs database
/usr/bin/mysqld_safe &
sleep 5
mysql -u root mysql -e "GRANT ALL PRIVILEGES ON *.* TO bugs@localhost IDENTIFIED BY 'bugs'; FLUSH PRIVILEGES;"
perl checksetup.pl /checksetup_answers.txt
mysqladmin -u root shutdown
