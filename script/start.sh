#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/home/ubuntu/app"      # ✅ 영속 경로
APP_DIR="$BASE_DIR/test2"
LOG_DIR="$BASE_DIR/logs"
PID_FILE="$BASE_DIR/app.pid"

PROFILE="${PROFILE:-dev}"
JAVA_OPTS="${JAVA_OPTS:-"-Xms512m -Xmx1024m"}"
PORT="${PORT:-8080}"

mkdir -p "$LOG_DIR"

# 이미 실행 중이면 중단
if [[ -f "$PID_FILE" ]] && ps -p "$(cat "$PID_FILE")" > /dev/null 2>&1; then
  echo "Already running with PID $(cat "$PID_FILE"). Stop first."
  exit 0
fi

# 최신 JAR 찾기 (Jenkins에서 빌드/번들링된 실행 JAR 전제)
JAR_FILE="$(ls -t "$APP_DIR"/build/libs/*.jar 2>/dev/null | head -n1 || true)"
if [[ -z "$JAR_FILE" ]]; then
  echo "JAR not found. (expected at $APP_DIR/build/libs)."
  exit 1
fi

echo "Starting: $JAR_FILE (profile=$PROFILE, port=$PORT)"
nohup java $JAVA_OPTS -jar "$JAR_FILE" \
  --spring.profiles.active="$PROFILE" \
  --server.port="$PORT" \
  > "$LOG_DIR/app.out" 2>&1 &

echo $! > "$PID_FILE"
echo "PID $(cat "$PID_FILE") started. Logs: $LOG_DIR/app.out"
