#!/bin/sh

case "$1" in
start|stop)

  old_cwd="`pwd`"
  cd "`dirname \"$0\"`"

  sh ./teamcity-server.sh $1

  cd ../buildAgent/bin
  sh ./agent.sh $1 $2

  cd "$old_cwd"
;;
*)
  echo "Run as $0 (start|stop[ force])"
  exit 1
;;
esac

