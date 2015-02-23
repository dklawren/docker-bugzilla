#!/bin/bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

set -e

# Output to log file as well as STDOUT/STDERR
exec > >(tee /runtests.log) 2>&1

echo "== Refreshing Bugzilla code"
cd $BUGZILLA_HOME
git stash
echo "Switching to $GITHUB_BASE_BRANCH ..."
git checkout -q $GITHUB_BASE_BRANCH
echo "Updating to latest ..."
git pull -q --rebase
if [ "$GITHUB_BASE_REV" != "" ]; then
    echo "Switching to $GITHUB_BASE_REV revision ..."
    git checkout -q $GITHUB_BASE_REV
fi

if [ "$TEST_SUITE" = "sanity" ]; then
    echo -e "\n== Running sanity tests"
    cd $BUGZILLA_HOME
    prove -f -v t/*.t
    exit $?
fi

if [ "$TEST_SUITE" = "docs" ]; then
    echo -e "\n== Running documentation build"
    export JADE_PUB=/usr/share/sgml
    export LDP_HOME=/usr/share/sgml/docbook/dsssl-stylesheets-1.79/dtds/decls
    cd $BUGZILLA_HOME/docs
    perl makedocs.pl --with-pdf
    exit $?
fi

echo -e "\n== Starting services"
# Database Start
echo "Starting database ..."
/usr/bin/mysqld_safe &
sleep 3
# Web Server
sed -e "s?#PerlSwitches?PerlSwitches?g" --in-place /etc/httpd/conf.d/bugzilla.conf
sed -e "s?#PerlConfigRequire?PerlConfigRequire?g" --in-place /etc/httpd/conf.d/bugzilla.conf
echo "Starting web server ..."
/usr/sbin/httpd &
sleep 3

echo -e "\n== Cloning QA test suite"
cd $BUGZILLA_HOME
echo "Cloning git repo $GITHUB_QA_GIT branch $GITHUB_BASE_BRANCH ..."
git clone $GITHUB_QA_GIT -b $GITHUB_BASE_BRANCH qa

echo -e "\n== Updating configuration"
sed -e "s?%DB%?$BUGS_DB_DRIVER?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%DB_NAME%?bugs_test?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%USER%?$BUGZILLA_USER?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%TRAVIS_BUILD_DIR%?$BUGZILLA_HOME?g" --in-place qa/config/selenium_test.conf

echo -e "\n== Running checksetup"
cd $BUGZILLA_HOME
rm ./data/params*
rm ./localconfig
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
    wget http://selenium-release.storage.googleapis.com/2.41/selenium-server-standalone-2.41.0.jar 1> /dev/null
    java -jar selenium-server-standalone-2.41.0.jar -DfirefoxDefaultPath=/usr/lib64/firefox/firefox \
        -log ~/selenium.log > /devnull 2>&1 &
    sleep 5

    echo -e "\n== Running Selenium UI tests"
    cd $BUGZILLA_HOME/qa/t
    prove -f -v -I$BUGZILLA_HOME/lib test_*.t
    exit $?
fi

if [ "$TEST_SUITE" = "webservices" ]; then
    echo -e "\n== Running WebService tests"
    cd $BUGZILLA_HOME/qa/t
    prove -f -v -I$BUGZILLA_HOME/lib webservice_*.t
    exit $?
fi
