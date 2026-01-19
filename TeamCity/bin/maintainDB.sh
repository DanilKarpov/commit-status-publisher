#!/bin/sh

# ---------------------------------------------------------------------
# TeamCity database maintenance script
# ---------------------------------------------------------------------
# Environment variables:
#
# TEAMCITY_MAINTAINDB_MEM_OPTS   memory options (JVM options)
#
# TEAMCITY_MAINTAINDB_OPTS       additional JVM options
#
# TEAMCITY_APP_DIR    Path to TeamCity application directory (default is <TeamCity_home>/webapps/ROOT)
#
# ---------------------------------------------------------------------


init_jre() {
      darwin=false
      # In Solaris, /bin/sh is not XPG4-compatible (unlike /usr/xpg4/bin/sh),
      # so here and below we use backticks (\`) instead of \$() to start a
      # subshell.
      case "`uname`" in
      Darwin*) darwin=true;;
      esac

      # Make sure prerequisite environment variables are set
      if [ -z "$JAVA_HOME" ] && [ -z "$JRE_HOME" ]; then
        if $darwin && [ -d "/System/Library/Frameworks/JavaVM.framework/Versions/1.5/Home" ]; then
          export JAVA_HOME="/System/Library/Frameworks/JavaVM.framework/Versions/1.5/Home"
        else
          echo "Neither the JAVA_HOME nor the JRE_HOME environment variable is defined"
          echo "Please make sure one of the environment variables is defined and is pointing to a valid Java (JRE) installation, then run again"
          exit 1
        fi
      fi

      if [ -z "$JRE_HOME" ]; then
        JRE_HOME="$JAVA_HOME"
      fi

}

set_paths(){

    if [ -z "$TEAMCITY_APP_DIR" ]; then
      TEAMCITY_APP_DIR=../webapps/ROOT
    fi
    TEAMCITY_LIB_DIR=$TEAMCITY_APP_DIR/WEB-INF/lib

    if [ ! -d "$TEAMCITY_LIB_DIR" ]; then
      echo "Critical error:  No TeamCity installation found ($TEAMCITY_LIB_DIR)"
      echo "Set TEAMCITY_APP_DIR variable to the TeamCity web application directory before running the script."
      exit 5
    fi

}

auto_classpath(){
  # "uname -o" is unavailable in OpenBSD and Solaris
  case `uname -s` in
    CYGWIN_NT-*|MINGW_NT-*|MINGW64_NT-*|MSYS_NT-*|MINGW32)
      # Prevent %windir%\system32\find.exe from appearing first in the PATH.
      PATH="`getconf PATH`"
      PATH_SEP=';'
      ;;
    *)
      PATH_SEP=':'
      ;;
  esac
  echo "$TEAMCITY_LIB_DIR"
  RESULT=`find "$TEAMCITY_LIB_DIR" -name "*.jar" 2>/dev/null | perl -pe "s/\\n/${PATH_SEP}/"`
  RETURN_CODE="$?"
  if [ "$RETURN_CODE" = "0" ]; then
    CP="$CP${PATH_SEP}$RESULT"
  fi
  unset PATH_SEP
}



old_cwd=`pwd`
BIN=`dirname $0`
cd $BIN

CP="$TEAMCITY_LIB_DIR/../classes"

init_jre ;
set_paths ;
auto_classpath ;

if [ "$TEAMCITY_MAINTAINDB_MEM_OPTS" = "" ]; then
    TEAMCITY_MAINTAINDB_MEM_OPTS="-Xmx1024m"
fi

MIGRATION_JVM_OPTS="$TEAMCITY_MAINTAINDB_OPTS -Dfile.encoding=utf-8 $TEAMCITY_MAINTAINDB_MEM_OPTS -XX:+HeapDumpOnOutOfMemoryError -Dteamcity_logs=`dirname $0`/../logs -Dlog4j2.configurationFile=`dirname $0`/../conf/teamcity-maintenance-log4j.xml"

"$JRE_HOME/bin/java" $MIGRATION_JVM_OPTS -cp "$CP" jetbrains.buildServer.serverSide.maintenance.BackupRestoreRunner "$@"

# Post-migration steps

check_result="$?"

cd "$old_cwd"
if [ "$check_result" != "0" ]; then
    echo "Critical error has occurred during command execution."
    exit $check_result 
else
    echo "Done."
    exit 0
fi



