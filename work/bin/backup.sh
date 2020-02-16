#!/bin/bash
#set -x

host=$(hostname)
today=$(date -u +%Y-%m-%d)

BACKUP_HOME="/misc/backup/${USER}"
BACKUP_SERVER="pi"
DEST="${BACKUP_HOME}/hosts/${host}/${today}"
LOG="/var/tmp/backup-${USER}-${host}-${today}.log"

RSYNC_OPTS="-e ssh -v -a -R"

# Snapshot keep settings
KEEP_COUNT_MIN=10
KEEP_MONTH_MIN=12

# need to keep
#  1st day of month
#  1st day of year

# day of year to keep forever, 1 - 365
YEAR_DAY_TO_KEEP=1
# day of month to keep (KEEP_MONTH_MIN), 1 - 31
MONTH_DAY_TO_KEEP=1

# Run with V=1 for debug, etc
if [ -z "$V" ] ; then
  V=3
fi

log() {
  local level=$1 ; shift
  local level_str=$1 ; shift
  local msg=$1 ; shift

  if [ $level -ge $V ] ; then
    printf "%s %s $msg\n" $(date -u -Iseconds) $level_str >> $LOG
  fi
}
debug() { log 1 "DEBUG" "$1"; }
info()  { log 3 "INFO" "$1"; }
warn()  { log 5 "WARN" "$1"; }
error() { log 6 "ERROR" "$1"; }

backup() {
  local path=$1; shift
  if [ -f $path ] || [ -d $path ] ; then
    info "backing up $path"

    if [ -n "$BACKUP_SERVER" ] ; then
      info "run: ssh $BACKUP_SERVER mkdir -p $DEST"
      ssh $BACKUP_SERVER "mkdir -p $DEST"
      info "run: rsync $RSYNC_OPTS $path $DEST"
      if ! rsync $RSYNC_OPTS $path $BACKUP_SERVER:$DEST >> $LOG ; then
        tail $LOG | mail -s "backup FAILED $path $today" shorne@gmail.com
      fi
    else
      info "run: rsync $RSYNC_OPTS $path $DEST"
      rsync $RSYNC_OPTS $path $DEST >> $LOG
    fi

    info "done"
  else
    warn "Backup path $path doesn't exist"
  fi
}

keep_snapshot() {
  snapshot=$1
  count_snapshots=$((count_snapshots+1))

  day_of_month=`date +'%d' -d "$snapshot"`
  day_of_year=`date +'%j' -d "$snapshot"`

  if [ $count_snapshots  -le $KEEP_COUNT_MIN ] ; then
    debug "Maintaining snapshot $snapshot as count $count_snapshots is less than $KEEP_COUNT_MIN"
    return 0
  fi
  if [ $month_snapshots  -le $KEEP_MONTH_MIN ] \
      && [ $day_of_month -eq $MONTH_DAY_TO_KEEP ] ; then
    debug "Maintaining month snapshot $snapshot as count $month_snapshots is less than $KEEP_MONTH_MIN"
    month_snapshots=$((month_snapshots+1))
    return 0
  fi
  if [ $day_of_year -eq $YEAR_DAY_TO_KEEP ] ; then
    debug "Maintaining year snapshot $snapshot"
    return 0
  fi
  return 1
}


##### MAIN #####

info "Starting: $0 user: $USER pid: $$ Logging to file: $LOG"

# 1. if local, remove old stuff
#  keep daily           snapshots for 1 week
#  keep weekly (sunday) snapshots for 1 year
#  keep yearly (jan 1)  snapshots forever 

if [ -d $BACKUP_HOME ] ; then
  info "Cleaning up $BACKUP_HOME"
  for snapshot in `find $BACKUP_HOME -maxdepth 3 | grep '/....-..-..$'`; do
    snapshot_dt=`basename $snapshot`
    if keep_snapshot $snapshot_dt; then
      info "Keeping snapshot $snapshot"
    else
      info "Purging snapshot $snapshot"
      rm -rf $snapshot
    fi
  done
fi

# 2. backup today
if [ -f $HOME/.backups ] ; then
  while read path; do
    backup $path </dev/null
  done <$HOME/.backups
else
  warn "No backups, you need to define $HOME/.backups"
fi

# Clean up old log files
find /var/tmp/backup-${USER}-* -mtime +5 -delete
