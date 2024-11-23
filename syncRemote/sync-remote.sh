#!/bin/bash

SCRIPT_PATH=$(realpath "$0")
PARENT_DIR=$(dirname "$SCRIPT_PATH")
PID_FILE="$PARENT_DIR"/process.pid

REMOTE=$1
PATH_TO_LOCAL=$2

start_sync() {
	echo "Start syncing remote $REMOTE to $PATH_TO_LOCAL"
	rclone --vfs-cache-mode writes mount "$REMOTE": "$PATH_TO_LOCAL" &
	echo $! > "$PID_FILE"
}

if [ -e "$PID_FILE" ]; then
	PID=$(cat "$PID_FILE")
	if ps -p "$PID" > /dev/null; then
		echo "Stop syncing remote $REMOTE to $PATH_TO_LOCAL"
		kill "$PID"
		rm "$PID_FILE"
	else
		start_sync
	fi
else
	start_sync
fi

