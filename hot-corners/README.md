# Hot Corners

A macOS-style hot corners plugin for Atmosphera. Move the pointer to a screen
corner to trigger its action after the dwell delay.

## Settings

Choose an action for each named corner from the searchable Atmosphera and loaded
plugin groups. Each field shows the action and the exact command it will run.
Actions with arguments expose labeled choice, number or text controls. Clear a
field to leave that corner inactive.

Type a command into search and select "Run command", or use "Custom command..."
to edit a literal command. For example: `atmosphera ipc controlCenter toggle` or
`niri msg action toggle-overview`. Changes are staged until Apply; canceling the
inline editor keeps its previous command. The shell's settings popup handles
unsaved changes when closing.

Settings remain one plain command string per corner, so existing commands keep
working. Requires Atmosphera 0.10.0 or newer.

## Credits

Originally written by sapjax for Noctalia Shell. MIT license.
