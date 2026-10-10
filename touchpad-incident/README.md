# Touchpad Incident

An Atmosphera-native top-bar button for marking an intermittent pointer jump or
phantom click without opening a terminal. Requires Atmosphera **0.7.0 or later**.

## What it does

- Click the pointer/exclamation icon immediately after noticing a symptom.
- Runs exactly `sudo -n -- /usr/local/bin/touchpad-incident`, without a shell,
  arguments, password dialog, screen recording or input injection.
- Shows a pointer/check icon and a confirmation toast after the helper confirms
  a saved marker. The underlying logger preserves its available prehistory and
  collects a 30-second tail.
- Uses one shared process and a 30-second successful-mark cooldown across all
  bar instances, avoiding duplicate markers from double/phantom clicks.
- Reports a failed command, invalid response or timeout instead of pretending
  evidence was saved. A timeout is ambiguous: inspect existing markers before
  retrying. Cancelling the helper client never stops the capture service.

The plugin is a marker frontend, **not the logger itself**. It does not diagnose
phantom clicks, record keyboard input, or claim sensor coordinates are cursor
coordinates. Preservation duration and quota are the logger's responsibility.

## Requirements

1. A local, running touchpad-coordinate logger and its root-owned
   `/usr/local/bin/touchpad-incident` helper. No logger installation or privilege
   changes are performed automatically by this plugin.
2. The helper must accept no arguments to mark an incident and print JSON with
   `{"incident": "...", "status": "collecting"}` on success. Errors should use
   a nonzero exit code and/or an `error` field.
3. The desktop user must be allowed to run **only that exact no-argument helper**
   noninteractively. The helper and every privileged dependency must be
   root-owned and not writable by the desktop user.

An administrator can use `sudo visudo -f /etc/sudoers.d/touchpad-incident` and
add the following, replacing `YOUR_USER` with the desktop login:

```sudoers
YOUR_USER ALL=(root) NOPASSWD: /usr/local/bin/touchpad-incident ""
```

The `""` explicitly permits **no command arguments**. Do not replace it with
`*`, grant broad Python/systemctl access, or make the helper user-writable.
Validate the administrator-created file with
`sudo visudo -cf /etc/sudoers.d/touchpad-incident` and keep it root:root 0440.
This rule does not grant permission to stop/start the logger, change its input
device, read its private raw files, or run `touchpad-incident status` password-free.

After that setup, invoking the command below **creates a real marker**; use a
planned check rather than running it repeatedly:

```sh
sudo -n -- /usr/local/bin/touchpad-incident
```

There is no fallback to a password prompt or terminal: missing permission/helper
or a stopped logger produces a visible failure.

## Installation

Install **Touchpad Incident** from the Atmosphera plugins source, enable it and
add its bar widget to the top bar. The source catalog uses the plugin id
`touchpad-incident`; installed source-backed keys include their source hash.
Manual/local installation follows Atmosphera's usual plugin workflow.

This plugin never restarts or reloads Atmosphera, niri, OpenCode or the logger.

## Optional IPC

The installed plugin exposes `plugin:touchpad-incident`:

- `mark` invokes the same debounced action as the button.
- `status` returns only this frontend's state and latest confirmation/error;
  it does not query privileged capture status or create a marker.

## Licensing

GPL-3.0, as covered by the repository's LICENSE. Author: Domovoy.
