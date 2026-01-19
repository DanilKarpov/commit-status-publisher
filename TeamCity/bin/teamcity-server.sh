#!/bin/sh

# ---------------------------------------------------------------------
# TeamCity server start/stop script (with auto restart support)
# ---------------------------------------------------------------------
# Environment variables:
#
# TEAMCITY_SERVER_MEM_OPTS   server memory options (JVM options)
#
# TEAMCITY_SERVER_OPTS       additional server JVM options
#
# TEAMCITY_DATA_PATH         path to TeamCity data directory
#
# TEAMCITY_LOGS_PATH         path to TeamCity logs directory
#
# TEAMCITY_PREPARE_SCRIPT    name of a script to execute before start/stop
#
# TEAMCITY_PID_FILE_PATH     path to a file which will contain TeamCity process ID (if not specified file with name "teamcity.pid" will be created under logs directory)
#
# TEAMCITY_RESTART_LIMIT     number of restart attempts on unexpected server exit (e.g. JVM crash), default is 3
#
# ---------------------------------------------------------------------

OLD_CWD=`pwd`
BIN=`dirname "$0"`
cd "$BIN"
BIN=`pwd`

if [ -z "$TEAMCITY_SERVER_SCRIPT" ]; then
  TEAMCITY_SERVER_SCRIPT="$BIN/teamcity-server.sh"
  export TEAMCITY_SERVER_SCRIPT
fi

if [ -z "$TEAMCITY_BIN_DIRECTORY" ]; then
  TEAMCITY_BIN_DIRECTORY="$BIN"
  export TEAMCITY_BIN_DIRECTORY
fi

TEAMCITY_SERVER_RESTARTER_SCRIPT="$BIN/teamcity-server-restarter.sh"
EXIT_CODE=0

_spawn_self() {
  echo "Spawning TeamCity restarter in separate process"
  sh "`basename "$0"`" "_start_internal" "$@" >/dev/null 2>&1 &
  ch_pid=$!
  echo "TeamCity restarter running with PID $ch_pid"
}

_do_cycle() {
  trap "echo 'Received stop signal'; sh `basename "$0"` stop; exit 0;" INT TERM HUP
  while true; do
    if [ -f "$TEAMCITY_SERVER_RESTARTER_SCRIPT.new" ]; then
      mv "$TEAMCITY_SERVER_RESTARTER_SCRIPT" "$TEAMCITY_SERVER_RESTARTER_SCRIPT.old"
      mv "$TEAMCITY_SERVER_RESTARTER_SCRIPT.new" "$TEAMCITY_SERVER_RESTARTER_SCRIPT"
      # Ensure correct permission set for new script
      chmod 755 "$TEAMCITY_SERVER_RESTARTER_SCRIPT"
    fi
    # Hack with spawning and waiting required for traps to work
    sh "$TEAMCITY_SERVER_RESTARTER_SCRIPT" "run" "$@" &
    wait $!
    EXIT_CODE=$?
    if [ ! -f "$TEAMCITY_SERVER_RESTARTER_SCRIPT.new" ]; then
      break
    fi
  done
}

if [ "$1" = "start" ]; then
  shift
  _spawn_self "$@"
  exit 0
elif [ "$1" = "run" ]; then
  shift
  _do_cycle "$@"
elif [ "$1" = "_start_internal" ]; then
  shift
  TEAMCITY_RESTARTER_SILENT=1
  export TEAMCITY_RESTARTER_SILENT
  _do_cycle "$@"
else
  sh "$TEAMCITY_SERVER_RESTARTER_SCRIPT" "$@"
  EXIT_CODE=$?
fi

exit $EXIT_CODE