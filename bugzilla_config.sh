#!/bin/bash

# Configure database
/usr/bin/mysqld_safe &
sleep 5
mysql -u root mysql -e "GRANT ALL PRIVILEGES ON *.* TO bugs@localhost IDENTIFIED BY 'bugs'; FLUSH PRIVILEGES;"
cd $BUGZILLA_HOME
perl checksetup.pl /checksetup_answers.txt
mysqladmin -u root shutdown
