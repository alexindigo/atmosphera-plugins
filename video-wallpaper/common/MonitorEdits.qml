import QtQuick

// A loaded projection is display state, not write intent. All selected forms
// submit through this boundary, including on monitor navigation. Control events
// retain deliberate equal-valued edits. A changed display buffer is never intent.
QtObject {
  required property var values
  property var baseline: ({})
  property var edited: ({})
  property int revision: 0
  property int generation: 0
  readonly property bool hasIntent: Object.keys(edited).length > 0

  function reset() {
    generation++;
    baseline = Object.assign({}, values);
    edited = ({});
  }

  function mark(field) {
    var next = Object.assign({}, edited);
    next[field] = ++revision;
    edited = next;
  }

  function submit(writer) {
    var captured = {
      generation: generation,
      values: Object.assign({}, values),
      edited: Object.assign({}, edited)
    };
    var pending = captured.values;
    for (var field of Object.keys(pending)) {
      if (edited[field])
        writer(field, pending[field]);
    }
    return captured;
  }

  function acknowledge(captured) {
    if (!captured || captured.generation !== generation)
      return;
    baseline = captured.values;
    var pending = Object.assign({}, edited);
    for (var field of Object.keys(captured.edited)) {
      if (pending[field] === captured.edited[field])
        delete pending[field];
    }
    edited = pending;
  }

  Component.onCompleted: reset()
}
