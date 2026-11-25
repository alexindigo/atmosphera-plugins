import QtQuick

Item {
    id: lifetime
    required property var sourceSettings
    readonly property var providerSettings: sourceSettings
    enabled: false
    property string leaseKey: ""
    property int leases: 0
    property var _requests: new Set()
    function request() {
        var xhr = new XMLHttpRequest(); _requests.add(xhr); return xhr;
    }
    function finishRequest(xhr) {
        if (!enabled || !_requests.has(xhr)) return false;
        _requests.delete(xhr); return true;
    }
    function hasPendingRequests(): bool {
        return _requests.size > 0;
    }
    function cancelRequests() {
        var requests = _requests; _requests = new Set();
        requests.forEach(xhr => { xhr.onreadystatechange = function() {}; xhr.abort(); });
    }
    onEnabledChanged: if (!enabled) cancelRequests()
    Component.onDestruction: cancelRequests()
}
