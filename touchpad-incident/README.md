# Touchpad Incident

An Atmosphera-native bar button for marking a pointer jump or phantom click.
Requires Atmosphera **0.8.0 or newer** and an installed compatible logger/helper.

## What it does

- Click the pointer/exclamation icon immediately after noticing a symptom.
- Calls exactly `/usr/local/bin/touchpad-incident` as the desktop user, with no
  arguments, shell, sudo or password dialog.
- Asks the logger to timestamp the incident and preserve its available
  prehistory plus a30-second tail. Confirmation appears only after the logger
  reports a saved marker.
- Uses one shared process and a30-second successful-mark cooldown across bars.
- Reports denied/unavailable control, invalid replies, failure or timeout.
  A timeout is ambiguous; inspect existing markers before retrying.

The frontend does not record keyboard input, inject events or diagnose the
hardware. Its coordinates/evidence semantics and retention are the logger's.

## Backend contract and setup

The privileged input reader owns the evidence and authorizes a normal desktop
user to send only marker requests. The frontend itself runs unprivileged.

1. Install the root-owned logger and `/usr/local/bin/touchpad-incident` helper.
   The plugin does not install/configure them automatically.
2. The administrator configures the allowed desktop account in the logger's
   service. This backend uses `TOUCHPAD_MARKER_USER=YOUR_USER` and named ACLs on
   its existing Unix control socket/directory. Socket peer credentials enforce
   the account and restrict unprivileged requests to `mark` and a read-only
   readiness `check`; detailed status and capture remain administrative.
3. The helper sends a marker request without sudo and prints JSON containing
   `{"incident": "...", "status": "collecting"}` on success. It exits nonzero
   for failures. Keep the helper, backend and their parent paths root-owned and
   not writable by the desktop user.

No NOPASSWD sudoers rule is required. An older logger/helper that only accepts
root must be upgraded alongside version1.0.1 of this frontend; replacing the
plugin alone cannot change its authorization policy.

Readiness can be verified without creating evidence:

```sh
/usr/local/bin/touchpad-incident check
```

It should return `{"ready": true, "can_mark": true}`. Running the helper with
**no arguments creates a real marker**; use the button when an issue occurs.
Detailed backend status can be inspected administratively with
`sudo /usr/local/bin/touchpad-incident status`.

## Installation and IPC

Install **Touchpad Incident** from **Settings → Plugins → Available → All**,
enable it and add its bar widget. Registry source-backed IDs include the
source hash. The frontend never automatically restarts the shell or logger.

`plugin:touchpad-incident` exposes:

- `mark`: the same debounced action as clicking the button.
- `status`: frontend state and last result/error only; creates no marker and
  does not expose privileged backend counters or raw evidence.

## License

GPL-3.0, covered by the repository LICENSE. Author: Domovoy.
