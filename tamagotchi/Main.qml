import QtQuick

Item {
    id: root
    property var pluginApi: null
    property var _games: new Map()
    // Preserve the original plugin-level background game, independent of views.
    readonly property var sharedGame: pluginApi?.settingsReady ? gameFor(pluginApi) : null
    Component { id: gameFactory; GameClient {} }

    function gameFor(api) {
        if (!api || !api.settingsReady || !api.settingsContext || !api.settingsContext.current()) return null;
        const context = api.settingsContext;
        if (_games.has(context)) return _games.get(context);
        const game = gameFactory.createObject(root, {
            runtimeApi: api,
            settingsContext: context,
            retire: function(retired) { root._games.delete(context); retired.destroy(); }
        });
        _games.set(context, game);
        return game;
    }
}
