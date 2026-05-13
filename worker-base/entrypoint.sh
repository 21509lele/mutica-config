#!/usr/bin/env bash
set -euo pipefail

: "${MULTICA_SERVER_URL:?MULTICA_SERVER_URL is required}"
: "${MULTICA_APP_URL:?MULTICA_APP_URL is required}"
: "${MULTICA_TOKEN:?MULTICA_TOKEN is required}"
: "${DEVICE_NAME:?DEVICE_NAME is required}"
: "${OPENAI_API_KEY:?OPENAI_API_KEY is required}"

CODEX_CONFIG_DIR="${CODEX_CONFIG_DIR:-/root/.codex}"
CODEX_MODEL_PROVIDER="${CODEX_MODEL_PROVIDER:-OpenAI}"
CODEX_MODEL="${CODEX_MODEL:-gpt-5.5}"
CODEX_MODEL_REASONING_EFFORT="${CODEX_MODEL_REASONING_EFFORT:-xhigh}"
CODEX_BASE_URL="${CODEX_BASE_URL:-https://api.hanbbq.top/v1}"

echo "[worker] initialize codex config"
mkdir -p "${CODEX_CONFIG_DIR}"
cat > "${CODEX_CONFIG_DIR}/config.toml" <<EOF
model_provider = "${CODEX_MODEL_PROVIDER}"
model = "${CODEX_MODEL}"
model_reasoning_effort = "${CODEX_MODEL_REASONING_EFFORT}"
disable_response_storage = true
approval_policy = "never"
sandbox_mode = "workspace-write"
personality = "pragmatic"
web_search = "live"
suppress_unstable_features_warning = true

[features]
plan_tool = true
apply_patch_freeform = true
view_image_tool = true
unified_exec = false
streamable_shell = false
rmcp_client = true

[model_providers.OpenAI]
name = "OpenAI"
base_url = "${CODEX_BASE_URL}"
wire_api = "responses"
requires_openai_auth = true

[sandbox_workspace_write]
network_access = true
EOF

cat > "${CODEX_CONFIG_DIR}/auth.json" <<EOF
{
  "OPENAI_API_KEY": "${OPENAI_API_KEY}"
}
EOF

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
