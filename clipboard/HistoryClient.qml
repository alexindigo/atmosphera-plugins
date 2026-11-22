import QtQuick
import Quickshell.Io

// Main owns content. This API-keyed client only projects that content using
// head's existing numeric domain; it never truncates the owner's observation.
Item {
    id: client
    required property var settingsContext
    required property var owner
    required property var retire
    readonly property bool current: settingsContext.current()
    readonly property var limit: settingsContext.settingsView.maxHistorySize ?? 100
    readonly property string source: owner.rawHistory
    property var items: []
    property int itemsRevision: 0
    property var request: null
    property bool constructed: false

    Component {
        id: projectionFactory
        Process {
            id: projection
            required property string payload
            required property string count
            command: ["head", "-n", count]
            stdinEnabled: true
            stdout: StdioCollector {}
            stderr: StdioCollector {}
            onExited: code => {
                if (client.current && client.request === projection) {
                    client.items = code === 0 ? client.owner.parseItems(stdout.text) : [];
                    client.itemsRevision++;
                    client.request = null;
                }
                projection.destroy();
            }
        }
    }
    function cancel() {
        const old = request;
        request = null;
        if (old) {
            old.running = false;
            old.destroy();
        }
    }
    function refresh() {
        cancel();
        if (!current) return;
        const projection = projectionFactory.createObject(client, {payload: source, count: String(limit)});
        request = projection;
        projection.running = true;
        projection.write(projection.payload);
        projection.stdinEnabled = false;
    }
    onSourceChanged: if (constructed) refresh()
    onLimitChanged: if (constructed) refresh()
    onCurrentChanged: {
        if (!constructed || current) return;
        cancel();
        items = [];
        itemsRevision++;
        retire(client);
    }
    Component.onCompleted: { constructed = true; refresh(); }
    Component.onDestruction: cancel()
}
