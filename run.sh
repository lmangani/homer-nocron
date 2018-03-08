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

export PATH_ROTATION_CONFIG=/opt/rotation.ini

perl -p -i -e "s/homer_user/$DB_USER/" $PATH_ROTATION_CONFIG
perl -p -i -e "s/homer_password/$DB_PASS/" $PATH_ROTATION_CONFIG
perl -p -i -e "s/localhost/$DB_HOST/" $PATH_ROTATION_CONFIG

# Init rotation
/opt/homer_mysql_rotate

# Sleep Function
sleep_until ()
{
  seconds=$(( $(date +%s) - $(date -d "$*" +%s) )) # calculate seconds distance to next rotation
  echo "Sleeping for $seconds seconds"
  sleep $seconds
}

# Run forever using $difference interval
ROTATION_TIME="${ROTATION_TIME:-04:00}"
while true; do /opt/homer_mysql_rotate; set -e; sleep_until $ROTATION_TIME; set +e; done 
