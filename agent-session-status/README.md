# Agent Session Status

Runs a local MCP Streamable HTTP service that agents can use to report session
state. The bar widget shows the number of running sessions; the panel groups all
reported sessions by agent.

## MCP Server Configuration

Configure the listen address, port, and token in plugin settings.

Example client configuration:

```json
{
  "mcpServers": {
    "noctalia-agent-sessions": {
      "type": "http",
      "url": "http://127.0.0.1:55854/mcp",
      "headers": {
        "Authorization": "Bearer <token>",
        "X-Agent": "codex"
      }
    }
  }
}
```

Allowed status values are `running`, `completed`, and `blocked`. Reusing the
same `X-Agent` and `id` updates the existing in-memory session. There is no
MCP delete tool; manual refresh removes non-running sessions, and all session
data is cleared when the plugin service restarts.

This service implements the JSON-RPC POST side of MCP Streamable HTTP. It does
not provide an SSE stream on `GET /mcp`.

## Instance settings and the shared service

Instances have independent polling and bar-visibility settings. Apply or Restart
admits that instance's address, port and token to the single managed service.
Restart clears the common in-memory sessions, as before; it does not create an
independent session store. Pending restarts retain their admitted policy and old
HTTP responses cannot overwrite a replacement service's results. Refresh/prune
uses the active service's credentials. Main/IPC remains explicitly plugin-level.
