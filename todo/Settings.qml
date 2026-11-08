import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets
import qs.Portals
import "Pages.js" as Pages

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var initial: pluginApi?.initialSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  NSettingsBaseline {
    id: displayBaseline
    readonly property bool valueShowCompleted: root.initial.showCompleted ?? root.defaults.showCompleted ?? true
    readonly property bool valueShowBackground: root.initial.showBackground ?? root.defaults.showBackground ?? true
    readonly property bool valueUseCustomColors: root.initial.useCustomColors ?? root.defaults.useCustomColors ?? false
    readonly property color valueHighPriorityColor: root.initial.priorityColors?.high || root.defaults.priorityColors?.high || AtmoColor.mError.toString()
    readonly property color valueMediumPriorityColor: root.initial.priorityColors?.medium || root.defaults.priorityColors?.medium || AtmoColor.mPrimary.toString()
    readonly property color valueLowPriorityColor: root.initial.priorityColors?.low || root.defaults.priorityColors?.low || AtmoColor.mOnSurfaceVariant.toString()
    readonly property string valueExportPath: root.initial.exportPath ?? root.defaults.exportPath ?? "~/Documents"
    readonly property string valueExportFormat: root.initial.exportFormat ?? root.defaults.exportFormat ?? "markdown"
    readonly property bool valueExportEmptySections: root.initial.exportEmptySections ?? root.defaults.exportEmptySections ?? false
    readonly property var editPages: root.initial.pages || [{id: 0, name: "General"}]
    readonly property var editTodos: root.initial.todos || []
    readonly property int editCurrentPage: root.initial.current_page_id ?? 0
    readonly property var pendingNames: Pages.names(editPages)
    readonly property string newPageName: ""
  }
  property var editPages: Pages.clone(displayBaseline.editPages)
  property var editTodos: Pages.clone(displayBaseline.editTodos)
  property int editCurrentPage: displayBaseline.editCurrentPage
  property var pendingNames: Pages.clone(displayBaseline.pendingNames)
  property string newPageName: ""
  readonly property bool settingsDirty: displayBaseline.differs({valueShowCompleted: valueShowCompleted, valueShowBackground: valueShowBackground, valueUseCustomColors: valueUseCustomColors, valueHighPriorityColor: valueHighPriorityColor, valueMediumPriorityColor: valueMediumPriorityColor, valueLowPriorityColor: valueLowPriorityColor, valueExportPath: valueExportPath, valueExportFormat: valueExportFormat, valueExportEmptySections: valueExportEmptySections, editPages: editPages, editTodos: editTodos, editCurrentPage: editCurrentPage, pendingNames: pendingNames, newPageName: newPageName})

  function setPendingName(id, value) {
    var next = Object.assign({}, pendingNames); next[String(id)] = value; pendingNames = next;
  }
  function renamePage(id, name) {
    name = name.trim();
    var index = editPages.findIndex(page => page.id === id);
    if (!name || !isPageNameUnique(name, index)) return false;
    editPages = Pages.rename(editPages, id, name);
    setPendingName(id, name);
    return true;
  }

  property bool valueShowCompleted: displayBaseline.valueShowCompleted
  property bool valueShowBackground: displayBaseline.valueShowBackground

  // Priority color properties
  property bool valueUseCustomColors: displayBaseline.valueUseCustomColors
  property color valueHighPriorityColor: displayBaseline.valueHighPriorityColor
  property color valueMediumPriorityColor: displayBaseline.valueMediumPriorityColor
  property color valueLowPriorityColor: displayBaseline.valueLowPriorityColor

  // Export path property
  property string valueExportPath: displayBaseline.valueExportPath
  property string valueExportFormat: displayBaseline.valueExportFormat
  property bool valueExportEmptySections: displayBaseline.valueExportEmptySections

  // Reference to Main.qml instance for centralized data management
  readonly property var mainInstance: pluginApi?.mainInstance

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.i("Todo", "Settings UI loaded");
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.show_completed.label")
    description: pluginApi?.tr("settings.show_completed.description")
    checked: root.valueShowCompleted
    onToggled: function (checked) {
      root.valueShowCompleted = checked;
    }
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.background_color.label")
    description: pluginApi?.tr("settings.background_color.description")
    checked: root.valueShowBackground
    onToggled: function (checked) {
      root.valueShowBackground = checked;
    }
  }

  // Toggle for custom priority colors
  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.custom_priority_colors.label")
    description: pluginApi?.tr("settings.custom_priority_colors.description")
    checked: root.valueUseCustomColors
    onToggled: function (checked) {
      root.valueUseCustomColors = checked;
    }
  }

  // Section for priority color settings (only visible when custom colors are enabled)
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    visible: root.valueUseCustomColors

    NText {
      text: pluginApi?.tr("settings.priority_colors.label")
      font.pointSize: Style.fontSizeL
      font.weight: Font.Bold
      Layout.topMargin: Style.marginL
    }

    GridLayout {
      columns: 2
      rowSpacing: Style.marginS
      columnSpacing: Style.marginM
      Layout.fillWidth: true

      // High priority color
      NText {
        text: pluginApi?.tr("settings.priority_colors.high_label")
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      }

      NColorPicker {
        id: colorPickerHigh
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.valueHighPriorityColor
        onColorSelected: function (color) {
          root.valueHighPriorityColor = color;
        }
      }

      // Medium priority color
      NText {
        text: pluginApi?.tr("settings.priority_colors.medium_label")
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      }

      NColorPicker {
        id: colorPickerMedium
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.valueMediumPriorityColor
        onColorSelected: function (color) {
          root.valueMediumPriorityColor = color;
        }
      }

      // Low priority color
      NText {
        text: pluginApi?.tr("settings.priority_colors.low_label")
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      }

      NColorPicker {
        id: colorPickerLow
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.valueLowPriorityColor
        onColorSelected: function (color) {
          root.valueLowPriorityColor = color;
        }
      }
    }
  }

  // Export path setting
  NTextInputButton {
    Layout.fillWidth: true
    label: pluginApi.tr("settings.export_path.label")
    description: pluginApi.tr("settings.export_path.description")
    placeholderText: pluginApi.tr("settings.export_path.placeholder")
    text: root.valueExportPath
    buttonIcon: "folder-open"
    buttonTooltip: pluginApi.tr("settings.export_path.select_folder")
    onInputEditingFinished: root.valueExportPath = text
    onButtonClicked: folderPicker.openFilePicker()
  }

  // Export format setting
  NComboBox {
    Layout.fillWidth: true
    label: pluginApi.tr("settings.export_format.label")
    description: pluginApi.tr("settings.export_format.description")
    model: [
      {
        key: "markdown",
        name: pluginApi.tr("settings.export_format.markdown")
      },
      {
        key: "json",
        name: pluginApi.tr("settings.export_format.json")
      }
    ]
    currentKey: root.valueExportFormat
    onSelected: function (key) {
      root.valueExportFormat = key;
    }
  }

  // Export empty sections setting
  NToggle {
    Layout.fillWidth: true
    label: pluginApi.tr("settings.export_empty_sections.label")
    description: pluginApi.tr("settings.export_empty_sections.description")
    checked: root.valueExportEmptySections
    onToggled: function (checked) {
      root.valueExportEmptySections = checked;
    }
  }

  // Folder picker for selecting export path
  PortalFilePicker {
    id: folderPicker
    selectionMode: "folders"
    title: pluginApi.tr("settings.export_path.label")
    initialPath: root.valueExportPath
    onAccepted: function (paths) {
      if (paths.length > 0) {
        root.valueExportPath = paths[0];
      }
    }
  }

  // Section for managing pages
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NText {
      text: pluginApi?.tr("settings.pages.label")
      font.pointSize: Style.fontSizeL
      font.weight: Font.Bold
      Layout.topMargin: Style.marginL
    }

    // Input for adding new pages
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NTextInput {
        id: newPageInput
        text: root.newPageName
        onTextEdited: root.newPageName = text
        placeholderText: pluginApi?.tr("settings.pages.placeholder")
        Layout.fillWidth: true
        Keys.onReturnPressed: addPage()
      }

      NButton {
        text: pluginApi?.tr("settings.pages.add_button")
        onClicked: addPage()
      }
    }

    // List of existing pages with proper scrolling
    Item {
      Layout.fillWidth: true
      height: 200

      Flickable {
        id: pagesListView
        anchors.fill: parent
        contentHeight: contentColumn.height
        clip: true
        boundsBehavior: Flickable.DragOverBounds

        ScrollBar.vertical: ScrollBar {
          parent: pagesListView
          anchors.top: pagesListView.top
          anchors.right: pagesListView.right
          anchors.bottom: pagesListView.bottom
          policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
          id: contentColumn
          width: parent.width
          spacing: Style.marginS

          Repeater {
            model: root.editPages

            delegate: Item {
              width: parent.width
              height: Style.baseWidgetSize

              property bool editing: false
              property string originalName: modelData.name || ""

              // Function to save the renamed page
              function saveRename() {
                var newName = renameInput.text.trim();
                if (newName === "") {
                  editing = false;
                  return;
                }

                if (newName === originalName) {
                  editing = false;
                  return;
                }

                if (!isPageNameUnique(newName, index)) {
                  ToastService.showError(pluginApi?.tr("settings.pages.name_exists"));
                  return;
                }

                // Use mainInstance to rename page
                root.renamePage(modelData.id, newName);

                originalName = newName;
                editing = false;
              }

              // Function to cancel renaming
              function cancelRename() {
                if (renameInput) {
                  root.setPendingName(modelData.id, originalName);
                }
                editing = false;
              }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.marginS
                anchors.rightMargin: Style.marginS
                spacing: Style.marginS

                // Container for the normal view (when not editing)
                Item {
                  Layout.fillHeight: true
                  Layout.fillWidth: true
                  visible: !editing

                  RowLayout {
                    anchors.fill: parent
                    spacing: Style.marginS

                    NText {
                      text: modelData.name
                      Layout.fillWidth: true
                      verticalAlignment: Text.AlignVCenter
                    }

                    AtmoIconButton {
                      icon: "pencil"
                      tooltipText: pluginApi?.tr("settings.pages.rename_button_tooltip")
                      onClicked: {
                        // Switch to editing mode and capture the current name
                        originalName = modelData.name;
                        editing = true;
                      }
                    }

                    AtmoIconButton {
                      icon: "trash"
                      tooltipText: pluginApi?.tr("settings.pages.delete_button_tooltip")
                      colorFg: AtmoColor.mError
                      enabled: root.editPages.length > 1 && modelData.id !== 0
                      onClicked: {
                        if (root.editPages.length <= 1) {
                          ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_last"));
                          return;
                        }

                        if (modelData.id === 0) {
                          ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_default"));
                          return;
                        }

                        // Show confirmation dialog before deleting
                        root.showDeleteConfirmation(index, modelData.name);
                      }
                    }
                  }
                }

                // Editing UI - only visible when in editing mode
                RowLayout {
                  Layout.fillHeight: true
                  Layout.fillWidth: true
                  spacing: Style.marginS
                  visible: editing

                  NTextInput {
                    id: renameInput
                    text: root.pendingNames[String(modelData.id)] || ""
                    onTextEdited: root.setPendingName(modelData.id, text)
                    Layout.fillWidth: true
                    Layout.preferredWidth: 150
                    focus: editing

                    Keys.onReturnPressed: saveRename()
                    Keys.onEscapePressed: cancelRename()

                    onVisibleChanged: {
                      if (visible && editing) {
                        root.setPendingName(modelData.id, originalName);
                        forceActiveFocus();
                      }
                    }
                  }

                  NButton {
                    text: "✓"
                    fontSize: Style.fontSizeS
                    backgroundColor: AtmoColor.mPrimary
                    textColor: AtmoColor.mOnPrimary
                    onClicked: saveRename()
                  }

                  NButton {
                    text: "✕"
                    fontSize: Style.fontSizeS
                    backgroundColor: AtmoColor.mError
                    textColor: AtmoColor.mOnError
                    onClicked: cancelRename()
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  function isPageNameUnique(name, excludeIndex) {
    var pages = editPages;
    var lowerName = name.toLowerCase().trim();
    for (var i = 0; i < pages.length; i++) {
      if (i !== excludeIndex && pages[i].name.toLowerCase().trim() === lowerName) {
        return false;
      }
    }
    return true;
  }

  function addPage() {
    var name = newPageName.trim();

    if (name === "") {
      ToastService.showError(pluginApi?.tr("settings.pages.empty_name"));
      return;
    }

    if (!isPageNameUnique(name, -1)) {
      ToastService.showError(pluginApi?.tr("settings.pages.name_exists"));
      return;
    }

    // Use mainInstance to create page
    editPages = Pages.create(editPages, name);
    pendingNames = Pages.names(editPages);

    newPageName = "";
    newPageInput.forceActiveFocus();
  }

  // Confirmation dialog for page deletion
  Popup {
    id: confirmDialog
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 300
    height: 150

    background: Rectangle {
      color: AtmoColor.mSurface
      border.color: AtmoColor.mOutline
      border.width: 1
      radius: Style.radiusL
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        id: confirmText
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Are you sure you want to delete this page?"
        verticalAlignment: Text.AlignVCenter
      }

      RowLayout {
        Layout.alignment: Qt.AlignRight
        spacing: Style.marginS

        NButton {
          text: "Cancel"
          onClicked: confirmDialog.close()
        }

        NButton {
          text: "Delete"
          textColor: AtmoColor.mOnError
          backgroundColor: AtmoColor.mError
          onClicked: {
            performPageDeletion(confirmDialog.pageIndex);
            confirmDialog.close();
          }
        }
      }
    }

    // Property to store the index of the page to delete
    property int pageIndex: -1
  }

  // Function to show the confirmation dialog
  function showDeleteConfirmation(pageIdx, pageName) {
    confirmDialog.pageIndex = pageIdx;
    var confirmMessage = pluginApi?.tr("settings.pages.confirm_delete_message");
    confirmText.text = confirmMessage.replace("{pageName}", pageName);
    confirmDialog.open();
  }

  // Function to perform the actual page deletion
  function performPageDeletion(pageIdx) {
    if (pageIdx < 0)
      return;

    var pages = editPages;

    // Prevent deleting default page (id: 0)
    if (pages[pageIdx].id === 0) {
      ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_default"));
      return;
    }

    if (pages.length <= 1) {
      ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_last"));
      return;
    }

    var pageToDeleteId = pages[pageIdx].id;

    // Use mainInstance to delete page (handles todos migration and current_page_id update)
    var next = Pages.remove(editPages, editTodos, editCurrentPage, pageToDeleteId);
    editPages = next.pages;
    editTodos = next.todos;
    editCurrentPage = next.current;
    pendingNames = Pages.names(editPages);
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Todo", "Cannot save settings: pluginApi is null");
      return;
    }

    if (newPageName.trim()) {
      if (!isPageNameUnique(newPageName.trim(), -1)) throw new Error("Duplicate page name");
      addPage();
    }
    for (var page of editPages) {
      if (!renamePage(page.id, pendingNames[String(page.id)] || "")) throw new Error("Invalid page name");
    }
    pendingNames = Pages.names(editPages);

    pluginApi.pluginSettings.showCompleted = root.valueShowCompleted;
    pluginApi.pluginSettings.showBackground = root.valueShowBackground;
    pluginApi.pluginSettings.useCustomColors = root.valueUseCustomColors;

    if (!valueUseCustomColors) {
      valueHighPriorityColor = AtmoColor.mError;
      valueMediumPriorityColor = AtmoColor.mPrimary;
      valueLowPriorityColor = AtmoColor.mOnSurfaceVariant;
    }
    pluginApi.pluginSettings.priorityColors = Object.assign({}, pluginApi.pluginSettings.priorityColors, {high: valueHighPriorityColor.toString(), medium: valueMediumPriorityColor.toString(), low: valueLowPriorityColor.toString()});
    pluginApi.pluginSettings.exportPath = valueExportPath;
    pluginApi.pluginSettings.exportFormat = valueExportFormat;
    pluginApi.pluginSettings.exportEmptySections = valueExportEmptySections;
    pluginApi.pluginSettings.pages = Pages.clone(editPages);
    pluginApi.pluginSettings.todos = Pages.clone(editTodos);
    pluginApi.pluginSettings.current_page_id = editCurrentPage;

    pluginApi.saveSettings();

    return;
  }
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if ((result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current") Logger.i("Todo", "Settings saved successfully");
    }
  }
}
