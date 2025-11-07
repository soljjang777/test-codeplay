#!/usr/bin/env bash
# 로컬 8081 포트 /health 체크
if curl -fsS http://127.0.0.1:8080/health >/dev/null; then
  echo "healthcheck OK"
  exit 0
else
  echo "healthcheck FAIL"
  exit 1
fi
