#!/bin/bash
set -euo pipefail

# ==== 설정값(필요시 환경변수로 덮어쓰기 가능) ====
APP_DIR="${APP_DIR:-/home/ubuntu/app}"
LOG_DIR="${LOG_DIR:-/home/ubuntu/app/logs}"
PID_FILE="${PID_FILE:-/home/ubuntu/app/app.pid}"

APP_PORT="${APP_PORT:-8080}"                 # Spring Boot 서버 포트
SPRING_PROFILE="${SPRING_PROFILE:-dev}"      # Spring profile
JAVA_OPTS="${JAVA_OPTS:--Xms512m -Xmx1024m}" # JVM 옵션 (원하면 조정)
JAR_NAME="${JAR_NAME:-}"                     # 특정 JAR를 지정하고 싶으면 값 지정

# ==== 준비 ====
mkdir -p "$APP_DIR" "$LOG_DIR"
cd "$APP_DIR"

# java 확인
if ! command -v java >/dev/null 2>&1; then
  echo "[start] java not found in PATH"
  exit 1
fi

# JAR 결정: JAR_NAME 지정이 없으면 app.jar 우선, 없으면 최신 *.jar
if [[ -n "$JAR_NAME" && -f "$JAR_NAME" ]]; then
  JAR="$JAR_NAME"
elif [[ -f app.jar ]]; then
  JAR="app.jar"
else
  JAR="$(ls -t *.jar 2>/dev/null | head -n1 || true)"
fi

if [[ -z "${JAR:-}" || ! -f "$JAR" ]]; then
  echo "[start] no jar found in $APP_DIR"
  exit 1
fi

# 중복 실행 방지: PID 파일/프로세스 체크
if [[ -f "$PID_FILE" ]]; then
  OLD_PID="$(cat "$PID_FILE" || true)"
  if [[ -n "${OLD_PID:-}" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo "[start] already running (pid=$OLD_PID). stop first or remove $PID_FILE if stale."
    exit 0
  else
    rm -f "$PID_FILE"
  fi
fi

# 포트가 이미 점유되어 있으면 경고 (필요시 강제 종료 로직 추가 가능)
if command -v lsof >/dev/null 2>&1; then
  if lsof -iTCP:"$APP_PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "[start] port $APP_PORT already in use"
    exit 1
  fi
fi

# ==== 실행 ====
echo "[start] launching $JAR on port $APP_PORT (profile=$SPRING_PROFILE)"
nohup java $JAVA_OPTS \
  -Dserver.port="$APP_PORT" \
  -Dspring.profiles.active="$SPRING_PROFILE" \
  -jar "$JAR" \
  > "$LOG_DIR/app.out" 2>&1 &

NEW_PID=$!
echo "$NEW_PID" > "$PID_FILE"
echo "[start] started pid=$NEW_PID, logs: $LOG_DIR/app.out"

# (옵션) 간단한 부팅 확인: 몇 초 대기 후 포트 확인
for i in {1..15}; do
  if command -v lsof >/dev/null 2>&1 && lsof -iTCP:"$APP_PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "[start] app is listening on $APP_PORT"
    exit 0
  fi
  sleep 1
done

echo "[start] started (pid=$NEW_PID) but port check did not confirm within timeout"
exit 0
