# Local client setup (Flow, meeting-capture)

Use this after the core stack is running (`bash scripts/dev-up.sh`, Brain on :8000, web on :5173).

## 1. Get a `pb_live_` API key

1. Open http://localhost:5173 and sign in (or sign up at `/signup`).
2. Go to **Connect App**.
3. Create an API key and copy the `pb_live_…` value.

This key is for Flow iOS and the meeting-capture extension. It is **not** the hex `PENLO_API_TOKEN` in `brain/.env` (that one is for Cursor MCP only).

## 2. Meeting Capture (Chrome)

1. Chrome → `chrome://extensions` → enable **Developer mode**.
2. **Load unpacked** → select folder: `meeting-capture/`
3. Extension popup:
   - **Brain base URL:** `http://localhost:8000` (origin only, no path)
   - **API key:** your `pb_live_…` key
4. Join Google Meet or Zoom with captions enabled. On meeting end, transcripts post to `POST /api/v1/ingest/standup`.

## 3. Flow iOS

1. Open the project: `open flow/flow.xcodeproj` (Xcode 16+).
2. **Settings → Enterprise Brain:**
   - **Simulator:** `http://localhost:8000`
   - **Physical device:** `http://<your-mac-lan-ip>:8000` (find IP in System Settings → Network)
3. Paste the same `pb_live_…` key → **Test Connection**.
4. Capture a conversation → approve in **Staging Vault** → confirm updates in web **Company Brain**.

## 4. Cursor MCP

Project config: `.cursor/mcp.json` (penlo-brain server). Reload MCP in Cursor settings after changes.

Backend must be running at http://localhost:8000.
