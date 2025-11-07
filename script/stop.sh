#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/home/ubuntu/app"
PID_FILE="$BASE_DIR/app.pid"
PORT="${PORT:-8080}"

if [[ -f "$PID_FILE" ]]; then
  PID="$(cat "$PID_FILE")"
  if ps -p "$PID" > /dev/null 2>&1; then
    echo "Stopping PID $PID"
    kill "$PID" || true
    for i in {1..30}; do
      ps -p "$PID" > /dev/null 2>&1 && sleep 1 || break
    end
    if ps -p "$PID" > /dev/null 2>&1; then
      echo "Force killing $PID"
      kill -9 "$PID" || true
    fi
  fi
  rm -f "$PID_FILE"
  echo "Stopped."
else
  echo "PID file not found. Trying by port $PORT..."
  if command -v lsof >/dev/null 2>&1 && lsof -t -i :"$PORT" >/dev/null 2>&1; then
    TARGET_PID="$(lsof -t -i :"$PORT" | head -n1)"
    kill "$TARGET_PID" || true
    sleep 3
    ps -p "$TARGET_PID" > /dev/null 2>&1 && kill -9 "$TARGET_PID" || true
    echo "Stopped (by port)."
  else
    echo "Nothing to stop."
  fi
fi
