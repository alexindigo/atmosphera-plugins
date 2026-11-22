# Noctalia Hermes Agent

A [Noctalia](https://github.com/noctalia-dev) plugin for [Hermes Agent](https://github.com/noctalia-dev/hermes-agent).

Shows Hermes status in the bar. Chat panel with streaming, tool activity, approval prompts, and one-shot. `>hermes` launcher integration. Drives a local or remote Hermes bridge.

## Install

Add the repo as a plugin source in Noctalia:

1. Settings → Plugins → Sources
2. Add custom repository: `https://github.com/Nomadcxx/noctalia-hermes-agent`
3. Settings → Plugins → Install — pick Hermes Agent

Or copy manually:

```bash
git clone https://github.com/Nomadcxx/noctalia-hermes-agent
cp -r noctalia-hermes-agent/hermes-agent/ ~/.config/noctalia/plugins/noctalia-hermes-agent/
```

Restart Noctalia.

## Architecture

The plugin runs in one of two modes:

**Normal mode (default).** A Python bridge process spawns locally on `127.0.0.1:19777`. The QML UI sends HTTP requests to it. The bridge talks to your Hermes gateway via RPC and reads your config and model catalog from `~/.hermes`.

**Client-only mode.** You run the bridge on a remote server. Forward its port to your local machine over SSH. The QML UI hits `127.0.0.1:19777` just like normal mode, but the SSH tunnel routes requests to the remote bridge. The remote bridge connects to the remote gateway. You paste the bridge token in Settings to authenticate.

```
Normal mode:        Client-only mode:

QML UI              QML UI
  │                   │
  ▼                   ▼
Bridge (local)      SSH tunnel (local port)
  │                   │
  ▼                   ▼ (SSH)
Gateway (local)     Bridge (remote)
                      │
                      ▼
                    Gateway (remote)
```

## Finite CLI lifetime

The local bridge owns its finite oneshot and gateway start/stop CLI invocations.
On Linux each invocation binds its lifetime to the bridge before executing its
literal argv. Bridge exit or the existing request timeout stops that invocation;
this does not stop intentionally independent gateway services or remote jobs.
No shell command interpretation or new process supervisor is introduced.

## Model picker

### Scoped settings and active chat

Placed-widget settings edit that instance; Settings > Plugins edits the shared
defaults. All views share one chat, bridge and gateway. Display and polling use
the selected context. Merely opening another Panel never selects its connection
or pin policy. A runtime pin action saves through its originating API.

Apply keeps the current chat, process and matching state/token readers. Changed
connection inputs show "pending restart" until explicit New Session or session
replacement. Finishing a prompt is not a restart boundary. Default model changes
use the acknowledged selected context; they are deferred with a pending connection
handoff. Test Connection probes the draft target independently and never selects
or restarts the running bridge. Local mode still fixes the bind host/default port.

The Settings dropdown lists providers and models from three sources:

1. **Provider config models** — your `config.yaml` providers section (e.g. `ollama-local.models`)
2. **Model catalog cache** — Hermes downloads this from its model catalog (`provider_models_cache.json`)
3. **Favorites** — models you previously used (`models.json`)

The list mirrors what `hermes --tui` shows. A provider may appear even without explicit config if Hermes ships a built-in overlay for it (like `minimax-oauth` or `kimi-for-coding`). Whether the model actually works depends on your API key and credentials.

To change the active model, select a provider/model in Settings and use the host's
Apply. Accepted completion calls `config.set` on the current bridge for the
selected configuration, unless its connection handoff is pending. The page's
Apply Model button requests trimming of the model/provider at that completion;
it does not publish the preference draft on its own.

## New Session and Reset

**New Session** tells the bridge to start a fresh Hermes RPC session. Chat history clears. This is the equivalent of `/session new` in the TUI.

The chat Panel's **Reset** starts a new Hermes session, like New Session. It is
distinct from the generic Settings host's staged configuration Reset.

## Client-only mode (remote bridge)

Run Hermes on a powerful server. Control it from your laptop. The bridge stays on the server bound to `127.0.0.1`. Your laptop reaches it through an SSH tunnel.

### Concepts

The **bridge** is a Python HTTP server on `127.0.0.1:19777` that sits between the QML UI and the Hermes gateway. It authenticates requests with a **bridge token** — a random secret generated on first launch and stored in `~/.cache/noctalia-hermes/bridge.token`.

In normal mode everything runs locally and the token is read from disk. In client-only mode you copy the token from the server and paste it into Settings. The plugin sends it in the `X-Bridge-Token` header with every request.

The bridge token is 43 characters of base64. It lives in the same directory as the state file and persists across restarts. Run `hermes-bridge-serve.sh` on the server to start the bridge and print the token and a ready-to-use SSH tunnel command.

### Setup

**On the server** (where Hermes and the gateway live):

```bash
cd hermes-agent/scripts
./hermes-bridge-serve.sh 19777
```

The script starts the bridge, prints the token, and shows the SSH command to run on your laptop. Example output:

```
Bridge env written to /home/user/.config/noctalia/plugins/.bridge.env
Token: I4ZvQnT0Bgf0FxL0azZgwYXb0KCruAMfVbGHH6WD7U

SSH tunnel command:
ssh -N -L 19777:127.0.0.1:19777 user@server
```

If you already have a token file, the script uses the existing one. Delete `~/.cache/noctalia-hermes/bridge.token` on the server to regenerate it. Only do this if you suspect the token leaked.

**On the laptop** (where Noctalia runs):

Open an SSH tunnel. Keep it alive while you use the plugin:

```bash
ssh -N -L 19777:127.0.0.1:19777 user@server
```

For a server on a different local port (e.g. a socat forwarder on `192.168.0.10:19778`):

```bash
ssh -N -L 19777:192.168.0.10:19778 user@gateway-host
```

**Plugin Settings** (Advanced section):

1. Enable **Client-only mode**
2. Set **Bridge host** to `127.0.0.1` (the tunnel endpoint) and **Bridge port** to `19777`
3. Paste the **Bridge token** from the server
4. Click **Apply**

The bar pill should turn green within a few seconds.

### Finding your token

- The bridge prints it on startup when you run `hermes-bridge-serve.sh`
- It lives in `~/.cache/noctalia-hermes/bridge.token` on the server
- Test Connection in Settings only checks `/health` (no token needed). A green result means the bridge is reachable. Use `curl` for a real `/state` check:

```bash
curl -H "X-Bridge-Token: <token>" http://127.0.0.1:19777/state
```

A 403 means the token is wrong. Compare character by character — leading dashes and trailing newlines are common mistakes.

### Troubleshooting

**Port already in use.** A local bridge process from before you turned on client-only mode, or a stale tunnel.

```bash
ss -ltnp | grep 19777
pkill -f hermes_bridge.py
```

**Bar pill grey or Offline.** The bridge reports `unknown` until a session runs. If the gateway is running the pill shows idle. Verify:

```bash
# Health (no token needed — confirms bridge is reachable)
curl -s 127.0.0.1:19777/health

# State (needs token — confirms auth and gateway status)
curl -s -H "X-Bridge-Token: <token>" 127.0.0.1:19777/state
```

**Toggle cycle (normal → client-only → normal).** Mode-dependent bridge host/port prevents the local token from hitting the remote bridge on toggle. Normal mode always uses `127.0.0.1:19777`. Client-only mode uses your configured host/port.

**Test Connection succeeds but bar shows offline.** The Test button only hits `/health`, which does not require a token. Check for a 403 on `/state` — wrong token, wrong host, or wrong port.

## Settings

| Setting | Default | Description |
|---|---|---|
| `bridgeHost` | `127.0.0.1` | Bridge host |
| `bridgePort` | `19777` | Bridge port |
| `stateFile` | `~/.cache/noctalia-hermes/state.json` | Shared state file |
| `hermesHome` | `~/.hermes` | Hermes home directory |
| `hermesCommand` | `hermes` | Hermes executable |
| `autoStartBridge` | `true` | Start local bridge at Noctalia load |
| `autoStartGateway` | `true` | Start gateway when bridge comes online |
| `clientOnlyMode` | `false` | Connect to a remote bridge over SSH |
| `bridgeTokenManual` | _(empty)_ | Bridge token (required in client-only mode) |
| `statusPollIntervalSec` | `30` | Status poll interval in seconds |
| `hideWhenIdle` | `false` | Hide bar pill when Hermes is idle |
| `launcherPrefix` | `>hermes` | Launcher command prefix |
| `panelPinned` | `false` | Pin panel as persistent side window |
| `showToolActivity` | `false` | Show compact tool-activity line |
| `defaultProvider` | _(empty)_ | Default provider |
| `defaultModel` | _(empty)_ | Default model |

## License

MIT
