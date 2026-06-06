#!/usr/bin/env bash
# Configure Penlo for iPhone + Mac LAN dev testing.
# Runs the Brain API natively on 0.0.0.0:8000 so iPhones can reach it (Colima
# Docker port-forward often blocks LAN clients). Postgres/Redis stay in Docker.
#
# Usage:
#   bash scripts/lan-dev.sh           # native API (recommended for phone testing)
#   bash scripts/lan-dev.sh --docker  # API in Docker (localhost only)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
USE_DOCKER=false
if [[ "${1:-}" == "--docker" ]]; then
  USE_DOCKER=true
fi

detect_lan_ip() {
  local ip=""
  for iface in en0 en1 bridge0; do
    ip="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"
    if [[ -n "$ip" ]]; then
      echo "$ip"
      return 0
    fi
  done
  return 1
}

is_private_ip() {
  local ip="$1"
  [[ "$ip" =~ ^10\. ]] && return 0
  [[ "$ip" =~ ^192\.168\. ]] && return 0
  [[ "$ip" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] && return 0
  return 1
}

LAN_IP="$(detect_lan_ip)" || {
  echo "ERROR: Could not detect LAN IP. Connect Wi‑Fi or iPhone hotspot, then retry."
  exit 1
}

WEB_ORIGIN="http://${LAN_IP}:5173"
API_ORIGIN="http://${LAN_IP}:8000"
WS_ORIGIN="ws://${LAN_IP}:8000"
NATIVE_PID_FILE="$ROOT/brain/.lan-dev-backend.pid"

echo "==> LAN IP: ${LAN_IP}"
if ! is_private_ip "$LAN_IP"; then
  echo ""
  echo "⚠️  Your Mac IP (${LAN_IP}) is not a home/private address."
  echo "   Many campus/corporate Wi‑Fi networks BLOCK phone↔laptop traffic."
  echo "   If iPhone Safari cannot open ${API_ORIGIN}/health, use this fix:"
  echo "     1. iPhone → Settings → Personal Hotspot → ON"
  echo "     2. Mac → Wi‑Fi → join your iPhone hotspot"
  echo "     3. Re-run: bash scripts/lan-dev.sh"
  echo ""
fi

echo "==> Patching web/.env.local"
cat > "$ROOT/web/.env.local" <<EOF
VITE_API_URL=${API_ORIGIN}
VITE_WS_URL=${WS_ORIGIN}
VITE_GOOGLE_CLIENT_ID=
EOF

echo "==> Patching brain/.env CORS + frontend URL (keeping PENLO_BASE_URL on localhost)"
ENV_FILE="$ROOT/brain/.env"
if [[ -f "$ENV_FILE" ]]; then
  ENV_FILE="$ENV_FILE" WEB_ORIGIN="$WEB_ORIGIN" python3 - <<'PY'
import os
import re
from pathlib import Path

web_origin = os.environ["WEB_ORIGIN"]
path = Path(os.environ["ENV_FILE"])
text = path.read_text()
origins = f"http://localhost:5173,http://localhost:3000,{web_origin}"

def set_line(key: str, value: str) -> None:
    global text
    pat = re.compile(rf"^{re.escape(key)}=.*$", re.M)
    line = f"{key}={value}"
    if pat.search(text):
        text = pat.sub(line, text)
    else:
        text = text.rstrip() + "\n" + line + "\n"

set_line("PENLO_FRONTEND_URL", web_origin)
set_line("CORS_ALLOWED_ORIGINS", origins)
path.write_text(text)
PY
else
  echo "WARNING: brain/.env missing — run bash scripts/generate-env.sh first"
fi

echo "==> Patching flow/Info.plist PENLO_WEB_BASE_URL"
PLIST="$ROOT/flow/Info.plist"
/usr/libexec/PlistBuddy -c "Set :PENLO_WEB_BASE_URL ${WEB_ORIGIN}" "$PLIST" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :PENLO_WEB_BASE_URL string ${WEB_ORIGIN}" "$PLIST"

if ! /usr/libexec/PlistBuddy -c "Print :NSAppTransportSecurity:NSExceptionDomains:${LAN_IP}" "$PLIST" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:${LAN_IP} dict" "$PLIST"
  /usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:${LAN_IP}:NSExceptionAllowsInsecureHTTPLoads bool true" "$PLIST"
  /usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:${LAN_IP}:NSIncludesSubdomains bool true" "$PLIST"
fi

export DOCKER_HOST="${DOCKER_HOST:-unix://${HOME}/.colima/default/docker.sock}"
export DOCKER_CONFIG="${DOCKER_CONFIG:-/tmp/penlo-docker-config}"
mkdir -p "$DOCKER_CONFIG"
echo '{"auths":{}}' > "$DOCKER_CONFIG/config.json"

echo "==> Ensuring Postgres + Redis are up"
cd "$ROOT/brain"
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d postgres redis

stop_native_backend() {
  if [[ -f "$NATIVE_PID_FILE" ]]; then
    local pid
    pid="$(cat "$NATIVE_PID_FILE")"
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      sleep 1
    fi
    rm -f "$NATIVE_PID_FILE"
  fi
}

if [[ "$USE_DOCKER" == true ]]; then
  stop_native_backend
  echo "==> Starting Brain backend in Docker"
  docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d backend
else
  echo "==> Stopping Docker backend (Colima port-forward blocks many LAN clients)"
  docker-compose -f docker-compose.yml -f docker-compose.dev.yml stop backend 2>/dev/null || true

  stop_native_backend

  echo "==> Starting Brain API natively on 0.0.0.0:8000 (reachable from iPhone)"
  BACKEND_DIR="$ROOT/brain/backend"
  if [[ ! -d "$BACKEND_DIR/.venv" ]]; then
    echo "ERROR: Missing $BACKEND_DIR/.venv — run: cd brain/backend && python3.11 -m venv .venv && pip install -r requirements.txt"
    exit 1
  fi
  # shellcheck disable=SC1091
  set -a
  source "$ROOT/brain/.env"
  set +a
  export SKIP_EMBEDDINGS="${SKIP_EMBEDDINGS:-true}"
  (
    cd "$BACKEND_DIR"
    source .venv/bin/activate
    exec uvicorn main:app --host 0.0.0.0 --port 8000
  ) >> "$ROOT/brain/.lan-dev-backend.log" 2>&1 &
  echo $! > "$NATIVE_PID_FILE"
fi

echo "Waiting for Brain API..."
for i in $(seq 1 30); do
  if curl -sf "${API_ORIGIN}/health" >/dev/null 2>&1; then
    echo "Brain API ready at ${API_ORIGIN}"
    break
  fi
  if [[ "$i" -eq 30 ]]; then
    echo "WARNING: Brain API did not respond on ${API_ORIGIN} within 60s"
    echo "         Check log: brain/.lan-dev-backend.log"
  fi
  sleep 2
done

FW_STATE="$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -o 'enabled' || true)"
if [[ -n "$FW_STATE" ]]; then
  echo ""
  echo "⚠️  macOS Firewall is ON."
  echo "   If iPhone still cannot connect, temporarily turn Firewall OFF to test,"
  echo "   or allow incoming connections for Python in System Settings → Firewall."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 1 — iPhone Safari (must work before Flow):"
echo "    ${API_ORIGIN}/health"
echo ""
echo "  STEP 2 — Web dashboard:"
echo "    cd web && npm run dev"
echo "    ${WEB_ORIGIN}/connect   ← create pb_live_ API key"
echo ""
echo "  STEP 3 — Flow app (rebuild in Xcode after Info.plist change):"
echo "    Brain URL:  ${API_ORIGIN}"
echo "    API key:    pb_live_… from Connect App"
echo ""
if [[ "$USE_DOCKER" != true ]]; then
  echo "  Native API log: brain/.lan-dev-backend.log"
  echo "  Stop native API: kill \$(cat brain/.lan-dev-backend.pid)"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
