#!/usr/bin/env bash
# Smoke-test local Penlo stack cohesion (brain API + auth + ingest + query).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API="${PENLO_API_URL:-http://localhost:8000}"
EMAIL="${SMOKE_EMAIL:-smoke-$(date +%s)@example.com}"
PASSWORD="${SMOKE_PASSWORD:-SmokeTest123!}"
COMPANY="${SMOKE_COMPANY:-Smoke Test Co}"

echo "==> Health check"
health=$(curl -sf "$API/health")
echo "$health" | grep -q '"status":"ok"' || { echo "Health failed: $health"; exit 1; }

echo "==> Company signup"
signup=$(curl -sf -X POST "$API/api/v1/auth/company" \
  -H 'Content-Type: application/json' \
  -d "{\"company_name\":\"$COMPANY\",\"admin_email\":\"$EMAIL\",\"admin_password\":\"$PASSWORD\",\"admin_name\":\"Smoke User\"}" \
  -c /tmp/penlo-smoke-cookies.txt) || {
  echo "Signup failed (ALLOW_COMPANY_SIGNUP may be false). Try logging in with existing credentials."
  exit 1
}

echo "==> Session check"
me=$(curl -sf "$API/api/v1/auth/me" -b /tmp/penlo-smoke-cookies.txt)
echo "$me" | grep -q "$EMAIL" || { echo "Session failed: $me"; exit 1; }

echo "==> Create API key"
key_resp=$(curl -sf -X POST "$API/api/v1/auth/api-keys" \
  -H 'Content-Type: application/json' \
  -b /tmp/penlo-smoke-cookies.txt \
  -d '{"name":"smoke-test"}')
API_KEY=$(echo "$key_resp" | python3 -c "import sys,json; print(json.load(sys.stdin)['key'])")

echo "==> Ingest penlo-brain (Contract v1.1)"
now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ingest=$(curl -sf -X POST "$API/api/v1/ingest/penlo-brain" \
  -H "Authorization: Bearer $API_KEY" \
  -H 'Content-Type: application/json' \
  -d "{\"schemaVersion\":\"1.1\",\"deviceID\":\"smoke-device\",\"userEmail\":\"$EMAIL\",\"syncedAt\":\"$now\",\"facts\":[{\"subject\":\"Smoke\",\"predicate\":\"verified\",\"object\":\"ingest\",\"confidence\":0.8,\"capturedAt\":\"$now\"}],\"people\":[],\"topicSummary\":[],\"vaultFiles\":[]}")
echo "$ingest" | grep -q '"status":"accepted"' || { echo "Ingest failed: $ingest"; exit 1; }

echo "==> Standup ingest"
standup=$(curl -sf -X POST "$API/api/v1/ingest/standup" \
  -H "Authorization: Bearer $API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"transcript":"Smoke standup notes","meeting_type":"ad_hoc"}')
echo "$standup" | grep -q '"status":"queued"' || { echo "Standup failed: $standup"; exit 1; }

echo "==> Query brain"
query=$(curl -sf -X POST "$API/api/v1/query" \
  -b /tmp/penlo-smoke-cookies.txt \
  -H 'Content-Type: application/json' \
  -d '{"question":"What is Penlo?","scope":"company"}')
echo "$query" | grep -q '"answer"' || { echo "Query failed: $query"; exit 1; }

echo "==> Graph company"
graph=$(curl -sf "$API/api/v1/graph/company" -b /tmp/penlo-smoke-cookies.txt)
echo "$graph" | grep -q '"nodes"' || { echo "Graph failed: $graph"; exit 1; }

echo ""
echo "All smoke checks passed against $API"
