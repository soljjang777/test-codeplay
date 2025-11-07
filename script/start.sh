#!/usr/bin/env bash
set -euo pipefail

# 프로젝트 루트 기준: script/ 와 test2/ 가 형제 디렉터리라고 가정
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$BASE_DIR/test2"
LOG_DIR="$BASE_DIR/logs"
PID_FILE="$BASE_DIR/app.pid"

PROFILE="${PROFILE:-dev}"          # 필요 시 PROFILE 환경변수로 변경 가능 (기본 dev)
JAVA_OPTS="${JAVA_OPTS:-"-Xms512m -Xmx1024m"}"
PORT=8080

mkdir -p "$LOG_DIR"

# 이미 떠 있으면 중단
if [[ -f "$PID_FILE" ]] && ps -p "$(cat "$PID_FILE")" > /dev/null 2>&1; then
  echo "Already running with PID $(cat "$PID_FILE"). Stop it first: $BASE_DIR/script/stop.sh"
  exit 1
fi

# 최신 JAR 찾기
JAR_FILE="$(ls -t "$APP_DIR"/build/libs/*.jar 2>/dev/null | head -n1 || true)"
if [[ -z "$JAR_FILE" ]]; then
  echo "JAR not found. Build first: (cd $APP_DIR && ./gradlew clean bootJar -x test)"
  exit 1
fi

echo "Starting: $JAR_FILE (profile=$PROFILE, port=$PORT)"
nohup java $JAVA_OPTS -jar "$JAR_FILE" \
  --spring.profiles.active="$PROFILE" \
  --server.port="$PORT" \
  > "$LOG_DIR/app.out" 2>&1 &

echo $! > "$PID_FILE"
echo "PID $(cat "$PID_FILE") started. Logs: $LOG_DIR/app.out"

# 헬스체크 대기 (/health 사용)
HEALTH_URL="http://127.0.0.1:${PORT}/health"
echo -n "Waiting for health at ${HEALTH_URL} "
for i in {1..60}; do
  if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
    echo -e "\nApplication is UP."
    exit 0
  fi
  echo -n "."
  sleep 1
done

echo -e "\nHealth check failed. See logs: $LOG_DIR/app.out"
exit 1
