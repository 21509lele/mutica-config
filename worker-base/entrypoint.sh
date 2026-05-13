#!/usr/bin/env bash
set -euo pipefail

: "${MULTICA_SERVER_URL:?MULTICA_SERVER_URL is required}"
: "${MULTICA_APP_URL:?MULTICA_APP_URL is required}"
: "${MULTICA_TOKEN:?MULTICA_TOKEN is required}"
: "${DEVICE_NAME:?DEVICE_NAME is required}"

echo "[worker] configure multica"
multica config set server_url "$MULTICA_SERVER_URL"
multica config set app_url "$MULTICA_APP_URL"

echo "[worker] login by token"
multica login --token "$MULTICA_TOKEN"

echo "[worker] installed agent CLIs:"
command -v codex || true
command -v gemini || true
command -v opencode || true

echo "[worker] start daemon: $DEVICE_NAME"
multica daemon start --device-name "$DEVICE_NAME"

echo "[worker] daemon status"
multica daemon status || true

tail -f /dev/null
