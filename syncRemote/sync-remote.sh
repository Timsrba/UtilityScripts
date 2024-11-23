#!/usr/bin/env bash

REMOTE=$1
PATH_TO_LOCAL=$2

SCRIPT_PATH=$(realpath "$0")
PARENT_DIR=$(dirname "$SCRIPT_PATH")
PID_FILE="$PARENT_DIR"/"$REMOTE".process.pid

start_sync() {
	echo "Start syncing remote $REMOTE to $PATH_TO_LOCAL"
	rclone --vfs-cache-mode writes mount "$REMOTE": "$PATH_TO_LOCAL" &
	echo $! > "$PID_FILE"
}

print_usage() {
	echo "Usage: $0 <remote_name> <path_to_local>"
	echo
	echo "Arguments:"
	echo "  <remote_name>    The name of the remote to sync (e.g., 'myremote')."
	echo "  <path_to_local>  The local directory to mount the remote to."
	echo
	echo "This script will mount the remote using rclone, or stop the mount if it's already running."
	echo "If the remote is already mounted, the script will terminate the process and remove the PID file."
	echo
	echo "If <remote_name> is not specified, the script will list the currently running remotes and ask you to select one to stop."
	echo "The selected remote will be stopped"
	exit 1
}

if [ -z "$REMOTE" ]; then
	REMOTES=()
	for file in "$PARENT_DIR"/*.process.pid;do
		if [ -f "$file" ];then
			remote=$(basename "$file" .process.pid)
			REMOTES+=("$remote")
		fi
	done
	if [ ${#REMOTES[@]} -gt 0 ];then
		PS3="Select remote to stop: "
		select remote in "${REMOTES[@]}"; do
			PID_FILE="$PARENT_DIR/$remote.process.pid"
			PID=$(cat "$PID_FILE")
			echo "Stop syncing remote $remote"
			kill "$PID"	
			rm "$PID_FILE"
			exit 0
		done
	else
		print_usage
	fi
fi

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
	if [ -z "$PATH_TO_LOCAL" ]; then
		print_usage
	else
		start_sync
	fi
fi

