import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets
import qs.Services.UI
import Quickshell.Io
import "Auth.js" as Auth

ColumnLayout {
    id: root
    NSettingsBaseline {
        id: displayBaseline
        readonly property string editClientId: root.pluginApi?.initialSettings?.clientId || root.pluginApi?.manifest?.metadata?.defaultSettings?.clientId || ""
        readonly property string editClientSecret: root.pluginApi?.initialSettings?.clientSecret || root.pluginApi?.manifest?.metadata?.defaultSettings?.clientSecret || ""
        readonly property string editPlayerId: root.pluginApi?.initialSettings?.playerId ?? root.pluginApi?.manifest?.metadata?.defaultSettings?.playerId ?? ""
        readonly property int editCallbackPort: root.pluginApi?.initialSettings?.callbackPort ?? root.pluginApi?.manifest?.metadata?.defaultSettings?.callbackPort ?? 8888
        readonly property string editAccessToken: root.pluginApi?.initialSettings?.accessToken || ""
        readonly property string editRefreshToken: root.pluginApi?.initialSettings?.refreshToken || ""
        readonly property double editTokenExpiresAt: root.pluginApi?.initialSettings?.tokenExpiresAt || 0
        ranges: [NSettingsRange { field: "editCallbackPort"; from: portInput.from; to: portInput.to }]
    }
    property string editAccessToken: displayBaseline.editAccessToken
    property string editRefreshToken: displayBaseline.editRefreshToken
    property double editTokenExpiresAt: displayBaseline.editTokenExpiresAt
    readonly property bool settingsDirty: displayBaseline.differs({editClientId: editClientId, editClientSecret: editClientSecret, editPlayerId: editPlayerId, editCallbackPort: editCallbackPort, editAccessToken: editAccessToken, editRefreshToken: editRefreshToken, editTokenExpiresAt: editTokenExpiresAt})
    property var _lifetime: ({alive: true})
    property var _tokenRequest: null
    property var _authInput: null
    Component.onDestruction: {
        _lifetime.alive = false;
        if (_tokenRequest) _tokenRequest.abort();
        callbackServer.running = false;
        getAvailableDevices.running = false;
        authProcess.running = false;
    }

    Process {
        id: callbackServer
        command: ["python3", pluginApi?.pluginDir + "/callback_server.py", String(root.editCallbackPort)]
        stdout: SplitParser {
            onRead: result => {
                const [code, state, error] = result.split(":")
                if (error !== "None") {
                    Logger.e("spotify-player", "Auth request returned with error:", error)
                    return
                }
                else if (state !== expectedState) {
                    Logger.w("spotify-player", "State mismatch in auth response")
                    return
                }
                else {
                    exchangeCodeForToken(code)
                }
            }
        }
    }

    Process {
        id: authProcess
        command: ["xdg-open"]
    }

    Process {
        id: getAvailableDevices
        command: ["curl", "https://api.spotify.com/v1/me/player/devices", "-H", "Authorization: Bearer " + root.editAccessToken]

        stdout: StdioCollector {
            onStreamFinished: {
                var response;
                try { response = JSON.parse(text); } catch (error) { Logger.e("spotify-player", "Invalid device response"); return; }
                const devices = response.devices || []
                availableDevices = ""
                for (const device of devices) {
                    availableDevices = availableDevices + device.name + ": " + device.id + "\n"
                }
                availableDevices = availableDevices.trim()
            }
        }
    }

    property var pluginApi: null

    property string availableDevices: ""

    onAvailableDevicesChanged: deviceList.text = availableDevices

    property string editClientId: displayBaseline.editClientId
    property string editClientSecret: displayBaseline.editClientSecret
    property string editPlayerId: displayBaseline.editPlayerId
    property int editCallbackPort: displayBaseline.project("editCallbackPort")

    // state will be checked when running auth process
    property string expectedState: ""
        

    spacing: Style.marginM

    Component.onCompleted: {
        Logger.i("spotify-player", "Settings UI loaded")
    }

    // Text input
    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.cid")
        description: pluginApi?.tr("settings.cid_desc")
        placeholderText: pluginApi?.tr("settings.cid_placeholder")
        text: root.editClientId
        onTextChanged: root.editClientId = text
    }

    // Text input
    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.secret")
        description: pluginApi?.tr("settings.secret_desc")
        placeholderText: pluginApi?.tr("settings.secret_placeholder")
        text: root.editClientSecret
        onTextChanged: root.editClientSecret = text
    }

    RowLayout {

        NText {
            text: pluginApi?.tr("settings.callback")
        }

        NSpinBox {
            id: portInput
            objectName: "settings-range-editCallbackPort"
            from: 0
            to: 65535
            value: root.editCallbackPort
            onValueModified: value => root.editCallbackPort = value
        }

        NText {
            text: pluginApi?.tr("settings.callback_warning")
            pointSize: Style.fontSizeS
        }
    }
    

    NText {
        text: pluginApi?.tr("settings.tokengen_info")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    NButton {
        text: pluginApi?.tr("settings.tokengen_btn")
        onClicked: startAuth()
    }

    NText {
        text: pluginApi?.tr("settings.devicelist_info")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    NButton {
        text: pluginApi?.tr("settings.devicelist_btn")
        onClicked: root.requestDevices()
    }

    TextArea {
        id: deviceList
        Layout.fillWidth: true
        Layout.maximumWidth: parent.width

        background: Rectangle {
            radius: Style.radiusS
            color: AtmoColor.mSurface
            border.color: AtmoColor.mSurfaceVariant
        }

        text: root.availableDevices
        readOnly: true
    }

    // Text input
    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.pid")
        description: pluginApi?.tr("settings.pid_desc")
        placeholderText: pluginApi?.tr("settings.pid_placeholder")
        inputMethodHints: Qt.ImhDigitsOnly
        text: root.editPlayerId
        onTextChanged: root.editPlayerId = text
    }

    
    function randomString(length) {
        const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        let result = ""
        for (let i = 0; i < length; i++) {
            result += chars.charAt(Math.floor(Math.random() * chars.length))
        }
        return result
    }

    function startAuth() {
        if (_tokenRequest || callbackServer.running) return;
        Logger.i("spotify-player", "Auth started")
        _authInput = {clientId: editClientId, clientSecret: editClientSecret, callbackPort: editCallbackPort};
    
        const state = randomString(16)
        expectedState = state
        const scope = "user-read-playback-state user-modify-playback-state playlist-read-private"
        const redirectUri = "http://127.0.0.1:" + _authInput.callbackPort + "/callback"

        const params = Auth.formEncode({
            response_type: "code",
            client_id: _authInput.clientId,
            scope: scope,
            redirect_uri: redirectUri,
            state: state
        })

        const url = "https://accounts.spotify.com/authorize?" + params

        Logger.i("spotify-player", "Starting auth")

        callbackServer.command = ["python3", pluginApi?.pluginDir + "/callback_server.py", String(_authInput.callbackPort)]
        callbackServer.running = true
        authProcess.command = ["xdg-open", url]
        authProcess.running = true
    }

    function exchangeCodeForToken(code) {
        if (!_authInput || _tokenRequest) return;
        callbackServer.running = false;
        requestToken(_authInput, {code: code, redirect_uri: "http://127.0.0.1:" + _authInput.callbackPort + "/callback", grant_type: "authorization_code"}, null);
    }

    function requestToken(input, values, after) {
        var lifetime = _lifetime;
        _tokenRequest = Auth.requestToken(Qt.btoa(input.clientId + ":" + input.clientSecret), values, function(tokens, error) {
            if (!lifetime.alive) return;
            root._tokenRequest = null;
            if (input.clientId !== root.editClientId || input.clientSecret !== root.editClientSecret || input.callbackPort !== root.editCallbackPort) return;
            if (error) { Logger.e("spotify-player", "Token request failed"); return; }
            root.editAccessToken = tokens.accessToken;
            if (tokens.refreshToken) root.editRefreshToken = tokens.refreshToken;
            root.editTokenExpiresAt = tokens.tokenExpiresAt;
            if (typeof after === "function") after();
        });
    }

    function requestDevices() {
        if (_tokenRequest || getAvailableDevices.running) return;
        if (editTokenExpiresAt > Date.now() || !editRefreshToken) getAvailableDevices.running = true;
        else requestToken({clientId: editClientId, clientSecret: editClientSecret, callbackPort: editCallbackPort}, {refresh_token: editRefreshToken, grant_type: "refresh_token"}, function() { getAvailableDevices.running = true; });
    }


    // Save function - called by the dialog
    function saveSettings() {
        if (!pluginApi) {
            Logger.e("spotify-player", "Cannot save: pluginApi is null")
            return
        }

        pluginApi.pluginSettings.clientId = root.editClientId
        pluginApi.pluginSettings.clientSecret = root.editClientSecret
        pluginApi.pluginSettings.playerId = root.editPlayerId
        pluginApi.pluginSettings.callbackPort = root.editCallbackPort
        pluginApi.pluginSettings.accessToken = root.editAccessToken
        pluginApi.pluginSettings.refreshToken = root.editRefreshToken
        pluginApi.pluginSettings.tokenExpiresAt = root.editTokenExpiresAt

        pluginApi.saveSettings()

    }
    Connections {
        target: root.pluginApi
        function onSettingsCompleted(result) {
            if ((result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current") Logger.i("spotify-player", "Settings saved successfully");
        }
    }
}
