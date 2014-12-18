#!/bin/bash

# Configure database
su postgres -c "/usr/bin/pg_ctl -D /var/lib/pgsql/data start" && sleep 5
su postgres -c "createuser --superuser bugs"
su postgres -c "psql -U postgres -d postgres -c \"alter user bugs with password 'bugs';\""
cd $BUGZILLA_HOME
perl checksetup.pl /checksetup_answers.txt
su postgres -c "/usr/bin/pg_ctl -D /var/lib/pgsql/data stop"

