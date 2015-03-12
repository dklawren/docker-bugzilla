#!/bin/bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

set -e

# Output to log file as well as STDOUT/STDERR
exec > >(tee /runtests.log) 2>&1

echo "== Retrieving Bugzilla code"
echo "Checking out $GITHUB_BASE_GIT $GITHUB_BASE_BRANCH ..."
mv $BUGZILLA_HOME "${BUGZILLA_HOME}.back"
git clone $GITHUB_BASE_GIT --single-branch --depth 1 --branch $GITHUB_BASE_BRANCH $BUGZILLA_HOME
cd $BUGZILLA_HOME
if [ "$GITHUB_BASE_REV" != "" ]; then
    echo "Switching to revision $GITHUB_BASE_REV ..."
    git checkout -q $GITHUB_BASE_REV
fi

if [ "$TEST_SUITE" = "sanity" ]; then
    cd $BUGZILLA_HOME
    /buildbot_step "Sanity" prove -f -v t/*.t
    exit $?
fi

if [ "$TEST_SUITE" = "docs" ]; then
    export JADE_PUB=/usr/share/sgml
    export LDP_HOME=/usr/share/sgml/docbook/dsssl-stylesheets-1.79/dtds/decls
    cd $BUGZILLA_HOME/docs
    /buildbot_step "Documentation" perl makedocs.pl --with-pdf
    exit $?
fi

echo -e "\n== Starting services"

# Database start
su postgres -c "/usr/bin/pg_ctl -D /var/lib/pgsql/data start" && sleep 5
sleep 3
# Web Server Start
echo "Starting web server ..."
sed -e "s?^#Perl?Perl?" --in-place /etc/httpd/conf.d/bugzilla.conf
/usr/sbin/httpd &
sleep 3
if [ "$GITHUB_BASE_BRANCH" = "master" ] || [ "$GITHUB_BASE_BRANCH" = "5.0" ]; then
    # Memcached Start
    echo "Starting memcached server ..."
    /usr/bin/memcached -u memcached -d
    sleep 3
fi

echo -e "\n== Cloning QA test suite"
cd $BUGZILLA_HOME
echo "Cloning git repo $GITHUB_QA_GIT branch $GITHUB_BASE_BRANCH ..."
git clone $GITHUB_QA_GIT -b $GITHUB_BASE_BRANCH qa

echo -e "\n== Updating configuration"
sed -e "s?%DB%?$BUGS_DB_DRIVER?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%DB_NAME%?bugs_test?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%USER%?$BUGZILLA_USER?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%TRAVIS_BUILD_DIR%?$BUGZILLA_HOME?g" --in-place qa/config/selenium_test.conf
if [ "$GITHUB_BASE_BRANCH" = "master" ] || [ "$GITHUB_BASE_BRANCH" = "5.0" ]; then
    echo "\$answer{'memcached_servers'} = 'localhost:11211';" >> qa/config/checksetup_answers.txt
fi

echo -e "\n== Running checksetup"
cd $BUGZILLA_HOME
./checksetup.pl qa/config/checksetup_answers.txt
./checksetup.pl qa/config/checksetup_answers.txt

echo -e "\n== Generating test data"
cd $BUGZILLA_HOME/qa/config
perl generate_test_data.pl

if [ "$TEST_SUITE" = "selenium" ]; then
    export DISPLAY=:0

    echo -e "\n== Starting virtual frame buffer"
    Xvfb $DISPLAY -screen 0 1024x768x24 > /dev/null 2>&1 &
    sleep 5

    echo -e "\n== Downloading and starting Selenium server"
    wget -q --progress=bar http://selenium-release.storage.googleapis.com/2.45/selenium-server-standalone-2.45.0.jar
    java -jar selenium-server-standalone-2.45.0.jar -log /selenium.log -browserSessionReuse > /dev/null 2>&1 &
    sleep 5

    cd $BUGZILLA_HOME/qa/t
    /buildbot_step "Selenium" prove -f -v -I$BUGZILLA_HOME/lib test_*.t
    exit $?
fi

if [ "$TEST_SUITE" = "webservices" ]; then
    cd $BUGZILLA_HOME/qa/t
    /buildbot_step "Webservices" prove -f -v -I$BUGZILLA_HOME/lib webservice_*.t
    exit $?
fi
