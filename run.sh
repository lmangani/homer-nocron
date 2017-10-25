#!/bin/bash
# ----------------------------------------------------
# HOMER 5 Docker (http://sipcapture.org)
# ----------------------------------------------------
# -- Run script for Homer's cron jobs
# ----------------------------------------------------
# Reads from environment variables to set:
# DB_PASS             MySQL password (homer_password)
# DB_USER             MySQL user (homer_user)
# DB_HOST             MySQL host (127.0.0.1 [docker0 bridge])
# ROTATION_TIME       MySQL rotation time in 24h format (ie: 04:00)
# ----------------------------------------------------

while [[ ! -f "/homer-semaphore/.bootstrapped" ]]; do
  echo "Homer cron container, waiting for MySQL"
  sleep 2;
done

# Work around key size constraints (noted in issue @ https://github.com/sipcapture/homer-docker/issues/42)
perl -p -i -e 's/\(`session_id`\)/(`session_id`(255))/' /opt/homer_mysql_rotate.pl 
perl -p -i -e 's/\(`correlation_id`\)/(`correlation_id`(255))/' /opt/homer_mysql_rotate.pl


# Reconfigure rotation

# --- I believe these are deprecated (@dougbtv, 3/30/17)
# export PATH_ROTATION_SCRIPT=/opt/homer_rotate
# chmod 775 $PATH_ROTATION_SCRIPT
# chmod +x $PATH_ROTATION_SCRIPT

export PATH_ROTATION_CONFIG=/opt/rotation.ini

perl -p -i -e "s/homer_user/$DB_USER/" $PATH_ROTATION_CONFIG
perl -p -i -e "s/homer_password/$DB_PASS/" $PATH_ROTATION_CONFIG
perl -p -i -e "s/localhost/$DB_HOST/" $PATH_ROTATION_CONFIG

# --- I believe these are deprecated (@dougbtv, 3/30/17)
# PERL_SCRIPTS=(/opt/homer_mysql_new_table.pl /opt/homer_mysql_partrotate_unixtimestamp.pl)
# for perl_script in ${PERL_SCRIPTS[@]}
# do
#   perl -p -i -e "s/homer_user/$DB_USER/" $perl_script
#   perl -p -i -e "s/homer_password/$DB_PASS/" $perl_script
#   perl -p -i -e "s/mysql_host = \"localhost\"/mysql_host = \"$DB_HOST\"/" $perl_script
# done

# Init rotation
/opt/homer_mysql_rotate.pl

# Sleep Function
function sleep_until {
  seconds=$(( $(date -d "$*" +%s) - $(date +%s) )) # Use $* to eliminate need for quotes
  echo "Sleeping for $seconds seconds"
  sleep $seconds
}

# Run forever using $difference interval
bash -c "while true; do /opt/homer_mysql_rotate.pl; set -e; sleep_until $ROTATION_TIME; set +e; done"   
