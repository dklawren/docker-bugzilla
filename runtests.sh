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
git checkout -q $GITHUB_BASE_BRANCH
git pull -q --rebase
if [ "$GITHUB_BASE_REV" != "" ]; then
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
    cd $BUGZILLA_HOME/docs
    perl makedocs.pl
    exit $?
fi

echo -e "\n== Starting services"
/usr/bin/mysqld_safe &
/usr/sbin/httpd &
sleep 5

echo -e "\n== Cloning QA test suite"
cd $BUGZILLA_HOME
/usr/bin/git clone $GITHUB_QA_GIT -b $GITHUB_BASE_BRANCH qa

echo -e "\n== Updating configuration"
sed -e "s?%BUGS_DB_DRIVER%?$BUGS_DB_DRIVER?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%BUGS_DB_NAME%?bugs?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%BUGS_DB_PASS%?bugs?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%BUGS_DB_HOST%?localhost?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%BUGZILLA_USER%?BUGZILLA_USER?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%BUGZILLA_URL%?$BUGZILLA_URL?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%ADMIN_EMAIL%?$ADMIN_EMAIL?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%ADMIN_PASSWORD%?$ADMIN_PASS?g" --in-place qa/config/checksetup_answers.txt
sed -e "s?%TRAVIS_BUILD_DIR%?$BUGZILLA_HOME?g" --in-place qa/config/selenium_test.conf

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
