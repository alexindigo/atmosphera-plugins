pragma Singleton
import QtQml

// The only shell service Main uses is logging. Keep this fixture isolated from
// unrelated shell-wide native modules while running the actual Main and helper.
QtObject {
    function w(...args) { console.warn(args.join(" ")); }
}
