import QtQuick
import Quickshell
import "../common"

ShellRoot {
    MonitorEdits { id: edits; values: ({automation: true, volume: 1.0}) }
    Timer {
        interval: 10; running: true
        onTriggered: {
            function check(ok, label) { if (!ok) throw new Error("MONITOR_EDITS_BUFFER_ASSERT: " + label); }
            try {
                var written = [];
                function writer(key, value) { written.push({key: key, value: value}); }
                edits.submit(writer); check(written.length === 0, "projection is not intent");
                edits.mark("automation");
                var first = edits.submit(writer);
                check(written.length === 1 && written[0].key === "automation", "equal value is intentional");
                check(edits.hasIntent, "submission and failure do not acknowledge");
                edits.mark("automation");
                edits.acknowledge(first); check(edits.hasIntent, "older receipt retains newer same-valued intent");
                var second = edits.submit(writer);
                edits.acknowledge(second); check(!edits.hasIntent, "current receipt acknowledges intent");
                edits.values = {automation: false, volume: 1.0};
                var direct = edits.submit(writer);
                check(written[written.length - 1].key === "automation" && written[written.length - 1].value === false, "direct alias edit");
                edits.values = {automation: false, volume: 0.5};
                edits.acknowledge(direct);
                var pending = [];
                edits.submit((key, value) => pending.push(key));
                check(pending.length === 1 && pending[0] === "volume", "receipt baseline retains newer direct edit");
                edits.reset(); edits.mark("volume");
                edits.acknowledge(second); check(edits.hasIntent, "receipt cannot acknowledge a different selection");
                console.log("MONITOR_EDITS_BUFFER: PASS"); Qt.quit();
            } catch (error) { console.error(String(error)); Qt.exit(2); }
        }
    }
}
