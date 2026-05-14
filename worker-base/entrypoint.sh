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
HOST_SSH_DIR="${HOST_SSH_DIR:-/host-ssh}"
GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"
GIT_SSH_KEY_FILE="${GIT_SSH_KEY_FILE:-id_ed25519_github}"
WORKER_RUNTIME_ROLE="${WORKER_RUNTIME_ROLE:-unknown}"

echo "[worker] runtime role: ${WORKER_RUNTIME_ROLE}"

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

if [ -d "${HOST_SSH_DIR}" ]; then
  echo "[worker] initialize ssh config"
  mkdir -p /root/.ssh
  cp -f "${HOST_SSH_DIR}/known_hosts" /root/.ssh/known_hosts 2>/dev/null || true
  cp -f "${HOST_SSH_DIR}/${GIT_SSH_KEY_FILE}" "/root/.ssh/${GIT_SSH_KEY_FILE}" 2>/dev/null || true
  cp -f "${HOST_SSH_DIR}/${GIT_SSH_KEY_FILE}.pub" "/root/.ssh/${GIT_SSH_KEY_FILE}.pub" 2>/dev/null || true
  chmod 700 /root/.ssh
  chmod 600 "/root/.ssh/${GIT_SSH_KEY_FILE}" 2>/dev/null || true
  chmod 644 /root/.ssh/known_hosts "/root/.ssh/${GIT_SSH_KEY_FILE}.pub" 2>/dev/null || true
  cat > /root/.ssh/config <<EOF
Host github.com
  HostName github.com
  User git
  IdentityFile /root/.ssh/${GIT_SSH_KEY_FILE}
  IdentitiesOnly yes
EOF
  chmod 600 /root/.ssh/config
fi

if [ -n "${GIT_USER_NAME}" ] || [ -n "${GIT_USER_EMAIL}" ]; then
  echo "[worker] initialize git config"
  {
    printf "[user]\n"
    [ -n "${GIT_USER_NAME}" ] && printf "\tname = %s\n" "${GIT_USER_NAME}"
    [ -n "${GIT_USER_EMAIL}" ] && printf "\temail = %s\n" "${GIT_USER_EMAIL}"
    printf "[safe]\n\tdirectory = *\n"
    printf "[core]\n\tsshCommand = ssh -i /root/.ssh/%s -o IdentitiesOnly=yes\n" "${GIT_SSH_KEY_FILE}"
  } > /root/.gitconfig
fi

echo "[worker] configure multica"
multica config set server_url "$MULTICA_SERVER_URL"
multica config set app_url "$MULTICA_APP_URL"

echo "[worker] login by token"
multica login --token "$MULTICA_TOKEN"

echo "[worker] installed agent CLIs:"
command -v codex || true
command -v gemini || true
command -v opencode || true

echo "[worker] start daemon: ${DEVICE_NAME} (role: ${WORKER_RUNTIME_ROLE})"
multica daemon start --device-name "$DEVICE_NAME"

echo "[worker] daemon status"
multica daemon status || true

tail -f /dev/null
