#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PID_FILE="$BASE_DIR/app.pid"
PORT=8080

if [[ ! -f "$PID_FILE" ]]; then
  echo "PID file not found ($PID_FILE). Trying to find process on port ${PORT}..."
  # 포트 기준으로 강제 종료 (최후 수단)
  if command -v lsof >/dev/null 2>&1 && lsof -t -i :"$PORT" >/dev/null 2>&1; then
    TARGET_PID="$(lsof -t -i :"$PORT" | head -n1)"
    echo "Killing PID $TARGET_PID (port $PORT)"
    kill "$TARGET_PID" || true
    sleep 3
    if ps -p "$TARGET_PID" > /dev/null 2>&1; then
      echo "Force killing PID $TARGET_PID"
      kill -9 "$TARGET_PID" || true
    fi
    echo "Stopped (by port)."
    exit 0
  else
    echo "Nothing to stop."
    exit 0
  fi
fi

PID="$(cat "$PID_FILE")"
if ps -p "$PID" > /dev/null 2>&1; then
  echo "Stopping PID $PID"
  kill "$PID" || true

  # 정상 종료 대기
  for i in {1..30}; do
    if ps -p "$PID" > /dev/null 2>&1; then
      sleep 1
    else
      break
    fi
  done

  if ps -p "$PID" > /dev/null 2>&1; then
    echo "Force killing PID $PID"
    kill -9 "$PID" || true
  fi
else
  echo "Process $PID not running."
fi

rm -f "$PID_FILE"
echo "Stopped."
