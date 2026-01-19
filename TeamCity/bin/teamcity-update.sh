#!/bin/sh
# This script is internal and should not be called directly, it's used during server auto update.

if [ $# -ne 2 ]; then
    echo This script is internal and should not be called directly, it is used during server auto update.
    exit 1
fi

CURRENT_DIR="$1"
UPDATE_DIR="$2"

_log() {
  echo "`date '+%Y-%m-%d %H:%M:%S %Z'`: $1"
}

_log "Starting update process"
"$JAVA_HOME"/bin/java -jar "$UPDATE_DIR/bin/teamcity-server-update.jar" "$CURRENT_DIR" "$UPDATE_DIR" 2>&1
code=$?
if [ $code -ne 0 ]; then
  _log "ERROR: Updater exited with non-zero code $code"
else
  _log "Update finished"
fi

if [ -d "$CURRENT_DIR/bin" ]; then
  find "$CURRENT_DIR/bin" -name '*.sh' -exec chmod +x '{}' \;
fi

