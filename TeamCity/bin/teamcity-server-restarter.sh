#!/bin/sh
# This script should not be called directly, use teamcity-server.sh instead

# Script to support TeamCity server auto restart
# Environment variables that may affect script:
#   * CATALINA_HOME
#   * CATALINA_BASE
#   * CATALINA_OUT

# Variables defined in this script:
#   * TEAMCITY_RESTART_LOCK_FILE_PATH  path to a file which will contain restarter lock, if file present server would automatically restart after exit

# Auto restart notes upon server process exit:
# If TEAMCITY_RESTART_LOCK_FILE_PATH is not preset, server would not be restarted


if [ "$TEAMCITY_SERVER_SCRIPT" = "" ]; then
  echo "This script should not be called directly, use teamcity-server.sh instead"
  exit 2
fi

RESTARTER_OLD_CWD=`pwd`

_exit() {
  cd "$RESTARTER_OLD_CWD"
  exit "$1"
}

_cd_to_bin() {
  BIN=`dirname "$0"`
  cd "$BIN"
  BIN=`pwd`
}
_cd_to_bin

case "$1" in
run|restart|stop|configure|status)
  # obsolete init. Use TEAMCITY_PREPARE_SCRIPT environment variable instead
  if [ -f "$BIN/teamcity-init.sh" ]; then
    . "$BIN/teamcity-init.sh"
  fi
;;
esac

if [ -z "$TEAMCITY_LOGS_PATH" ]; then
  TEAMCITY_LOGS_PATH="$BIN/../logs"
  export TEAMCITY_LOGS_PATH
fi
mkdir -p "$TEAMCITY_LOGS_PATH"

# Setup variables
TEAMCITY_RESTART_LOCK_FILE_PATH="$TEAMCITY_LOGS_PATH/teamcity.lock"
TEAMCITY_RESTART_REQUESTED_FILE_PATH="$TEAMCITY_LOGS_PATH/teamcity.restart"
if [ -z "$TEAMCITY_RESTART_LIMIT" ]; then
  TEAMCITY_RESTART_LIMIT=3
fi
if [ -z "$MAX_CATALINA_OUT_SIZE" ]; then
  MAX_CATALINA_OUT_SIZE=2147483648
fi
if [ -z "$TEAMCITY_PID_FILE_PATH" ]; then
  TEAMCITY_PID_FILE_PATH="$TEAMCITY_LOGS_PATH/teamcity.pid"
fi

# Only set CATALINA_HOME if not already set
[ -z "$CATALINA_HOME" ] && CATALINA_HOME=`cd ".." >/dev/null; pwd`
# Copy CATALINA_BASE from CATALINA_HOME if not already set
[ -z "$CATALINA_BASE" ] && CATALINA_BASE="$CATALINA_HOME"
if [ -z "$CATALINA_OUT" ] ; then
  CATALINA_OUT="$TEAMCITY_LOGS_PATH/catalina.out"
fi


if [ "$TEAMCITY_SERVER_MEM_OPTS" = "" ]; then
  # Default options suitable for product evaluation
  TEAMCITY_SERVER_MEM_OPTS="-Xmx1024m"
fi

TEAMCITY_SERVER_OPTS="$TEAMCITY_SERVER_OPTS"
export TEAMCITY_SERVER_OPTS

CATALINA_OPTS="$CATALINA_OPTS $TEAMCITY_SERVER_OPTS -server $TEAMCITY_SERVER_MEM_OPTS"

CATALINA_OPTS="$CATALINA_OPTS -Dteamcity.configuration.path=\"../conf/teamcity-startup.properties\" -Dlog4j2.configurationFile=\"file:$BIN/../conf/teamcity-server-log4j.xml\" -Dteamcity_logs=\"$TEAMCITY_LOGS_PATH\" -Djava.awt.headless=true"
export CATALINA_OPTS

CATALINA_PID="$TEAMCITY_PID_FILE_PATH"
export CATALINA_PID

# Add the Java 9 specific parameter, required by some TeamCity inner functionality
JDK_JAVA_OPTIONS="$JDK_JAVA_OPTIONS --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED -XX:+IgnoreUnrecognizedVMOptions"

if [ "${CATALINA_OPTS##*ReservedCodeCacheSize*}" = "$CATALINA_OPTS" ]; then
  JDK_JAVA_OPTIONS="$JDK_JAVA_OPTIONS -XX:ReservedCodeCacheSize=640M"
fi

export JDK_JAVA_OPTIONS

LOG="$TEAMCITY_LOGS_PATH/teamcity-wrapper.log"

# unset environment variable because we will create necessary file from script, see below
unset TEAMCITY_PID_FILE_PATH

TC_EXIT_CODE=0

TEAMCITY_RESTARTER_SILENT_ACTUAL="$TEAMCITY_RESTARTER_SILENT"
# prevent env spoiling
unset TEAMCITY_RESTARTER_SILENT

QUIET=0

_log() {
  mkdir -p "$TEAMCITY_LOGS_PATH"
  touch $LOG
  echo "`date '+%Y-%m-%d %H:%M:%S %Z'`: $1" >> $LOG
  if [ -z "$TEAMCITY_RESTARTER_SILENT_ACTUAL" ]; then
    echo "`date '+%Y-%m-%d %H:%M:%S %Z'`: $1"
  fi
}

_do_default() {
  mkdir -p "$TEAMCITY_LOGS_PATH" 2>/dev/null
  if [ "$TEAMCITY_PREPARE_SCRIPT" != "" ]; then
      "$TEAMCITY_PREPARE_SCRIPT" "$@"
  fi
  case "$1" in
    configure|status)
      if [ "$1$2" == "statusshort" ]; then
        QUIET=1
      fi
      check_java
      TEAMCITY_CONFIGURATOR_JAR="teamcity-server-configurator.jar"
      "$java_exec" $JAVA_OPTS -jar "$TEAMCITY_CONFIGURATOR_JAR" "$@"
      TC_EXIT_CODE=$?
    ;;
    run)
      # Hack with spawning and waiting required for traps to work
      # Check silent for thew case when started as 'start', so TC won't spoil wrapper log
      if [ "$TEAMCITY_RESTARTER_SILENT_ACTUAL" != "" ]; then
        _roll "$@"
        ./catalina.sh "$@" >> "$CATALINA_OUT" 2>&1 &
        tc_pid=$!
      else
        ./catalina.sh "$@" 2>&1 &
        tc_pid=$!
      fi
      _log "TeamCity process PID is $tc_pid"

      # Wait for some time prior to saving pid file, catalina may exit abruptly with exit code 0 if failed to bind address
      # Otherwise we can end un in situation when pid of wrong server overrides pid of correct one
      minus_p=''
      if ps -p 1 >/dev/null 2>/dev/null; then
        minus_p='-p'
      fi
      # In case of abrupt exit we want to be informed as quickly as possibly, though max waiting time is one minute
      for interval in 5 5 10 10 15 15; do
        sleep $interval
        if ! ps $minus_p $tc_pid >/dev/null 2>&1; then
          break
        fi
      done
      if ps $minus_p $tc_pid >/dev/null 2>&1; then
        echo $tc_pid > "$CATALINA_PID"
      fi

      wait $tc_pid
      TC_EXIT_CODE=$?
    ;;
    *)
      ./catalina.sh "$@"
      TC_EXIT_CODE=$?
    ;;
  esac
}

_roll() {
  if [ "$TEAMCITY_RESTARTER_NO_ROLL" = "" ]; then
    if [ -f "$CATALINA_OUT" ]; then
      _roll_file_by_size "$@"
    fi
  fi
}

_roll_file_by_size() {
  FILE_SIZE=`LC_ALL=C ls -dn -- "$CATALINA_OUT" | awk '{print $5; exit}'`
  DATE="$(date +"%Y-%m-%d_%H-%M-%S")"
  NEW_NAME="${CATALINA_OUT%.*}.$DATE.${CATALINA_OUT##*.}"
  if [ ${FILE_SIZE} -gt ${MAX_CATALINA_OUT_SIZE} ]; then
    mv "$CATALINA_OUT" "$NEW_NAME"
  fi
}

_restarter_run() {
  mkdir -p "$TEAMCITY_LOGS_PATH" 2>/dev/null
  if [ -f "$TEAMCITY_RESTART_LOCK_FILE_PATH" ]; then
    # TODO: Check server not running
    echo "Existing lock file found, would be removed"
    rm "$TEAMCITY_RESTART_LOCK_FILE_PATH"
  fi

  TEAMCITY_RESTART_COUNT=0

  # Setting trap so signal to this shell would terminate server gracefully
  trap "echo 'Received stop signal'; sh `basename "$0"` stop; exit 0;" INT TERM HUP

  while true; do
    _log "Starting TeamCity server"
    rm -f "$TEAMCITY_RESTART_LOCK_FILE_PATH"
    touch "$TEAMCITY_RESTART_LOCK_FILE_PATH"
    if [ $? -eq 0 ]; then
      export TEAMCITY_RESTART_LOCK_FILE_PATH
    else
      _log "Failed to create lock file. Auto restart and upgrade functionality is unavailable"
      TEAMCITY_RESTART_LOCK_FILE_PATH=""
    fi

    _do_default "$@"

    if [ -z "$TEAMCITY_RESTART_LOCK_FILE_PATH" ]; then
      break
    fi

    if [ ! -f "$TEAMCITY_RESTART_LOCK_FILE_PATH" ]; then
      _log "Server exited with code $TC_EXIT_CODE"
      break
    fi

    if [ $TC_EXIT_CODE -eq 0 -a -f "$TEAMCITY_RESTART_REQUESTED_FILE_PATH" ]; then
      rm "$TEAMCITY_RESTART_REQUESTED_FILE_PATH"
      TEAMCITY_RESTART_COUNT=0
      _log "Server exited with code $TC_EXIT_CODE and will be restarted: requested-restart marker file found"
    else
      # Restart after crash or abrupt finish (busy ports)
      TEAMCITY_RESTART_COUNT=`expr $TEAMCITY_RESTART_COUNT + 1`
      if [ "$TEAMCITY_RESTART_COUNT" -lt "$TEAMCITY_RESTART_LIMIT" ]; then
        _log "Server exited unexpectedly with code $TC_EXIT_CODE and will be restarted"
      else
        _log "Server exited unexpectedly with code $TC_EXIT_CODE and restart limit ($TEAMCITY_RESTART_LIMIT) is reached" 1>&2
        break
      fi
    fi
  done
}

check_java() {
  . ./findJava.sh
  FJ_MIN_UNSUPPORTED_JAVA_VERSION=22
  FJ_LOOK_FOR_SERVER_JAVA=1
  #Uncomment next line to search only for x64 JDK
  #FJ_LOOK_FOR_X64_JAVA=1
  find_java 1.8 "$TEAMCITY_JRE" "$(pwd)/../jre"
  if [ $? -ne 0 ]; then
    if [ "$QUIET" -eq 0 ]; then
      echo "Java not found. Cannot start TeamCity server. Please ensure JDK or JRE is installed and JAVA_HOME environment variable points to it."
    fi
    _exit 1
  fi
  # Lets use java found by findJava.sh
  java_exec="$FJ_JAVA_EXEC"
  if [ "$QUIET" -eq 0 ]; then
    echo "Java executable is found: '$FJ_JAVA_EXEC'"
  fi
  java_bin_dir="`dirname \"$FJ_JAVA_EXEC\"`"
  JAVA_HOME="`dirname \"$java_bin_dir\"`"

  # Enable security manager explicitly for Java > 17 (21 and above)
  version_ge "$FJ_JAVA_VERSION" "17"
  if [ $? -eq 0 ]; then
    JDK_JAVA_OPTIONS="$JDK_JAVA_OPTIONS -Djava.security.manager=allow"
  fi

  unset FJ_JAVA_EXEC
  export JAVA_HOME
  # Ensure catalina.sh won't take some other one
  unset JRE_HOME
}

# 'start' no longer supported, it's implemented in teamcity-server.sh
case "$1" in
run)
  check_java
  _restarter_run "$@"
;;
restart)
  shift
  check_java
  touch "$TEAMCITY_RESTART_REQUESTED_FILE_PATH"
  if [ $? -eq 0 ]; then
    _log "Successfully created restart marker file"
    _do_default stop "$@"
  else
    _log "Failed to create restart mark file. Restart functionality is unavailable"
    TC_EXIT_CODE=1
  fi
;;
stop)
  if [ -f "$TEAMCITY_RESTART_LOCK_FILE_PATH" ]; then
    echo "Removing lock file so server won't automatically restart"
    rm "$TEAMCITY_RESTART_LOCK_FILE_PATH"
  fi
  check_java
  _do_default "$@"
;;
configure|status)
  _do_default "$@"
;;
*)
  echo "Usage: teamcity-server.sh ( commands ... )"
  echo "commands:"
  echo "  start             Starts the TeamCity server as a separate process."
  echo "  run               Starts the TeamCity server in the current terminal."
  echo "  stop              Sends the stop command to the TeamCity server and waits up to 5 seconds for the process to end."
  echo "  stop n            Sends the stop command to the TeamCity server and waits up to n seconds for the process to end."
  echo "  stop n -force     Sends the stop command to the TeamCity server, waits up to n seconds for the process to end, kills the server process if it is still running."
  echo "  restart           Restarts the running TeamCity server."
  echo "  restart n -force  Restarts the running the TeamCity server after stopping it using the 'stop n -force' command."
  TC_EXIT_CODE=1
;;
esac

_exit $TC_EXIT_CODE